%% 延遲波包（Delayed Wavepacket at Omega_c）三重延遲機制深度對比實驗
% 檔案名稱: wavepacket_three_delays_experiment.m
% 說明:
%   本腳本對比三種延遲機制對波包（Wavepacket）時域與頻域特性的影響：
%     1. 純包絡延遲 (Envelope-only Delay, tau_e = tau, tau_c = 0)
%     2. 純載波延遲 (Carrier tone-only Delay, tau_e = 0, tau_c = tau)
%     3. 兩者皆延遲 / 全延遲 (True Time Delay, TTD, tau_e = tau, tau_c = tau)
%
%   重點驗證：
%     - 振幅譜 |X(f)| 三者完全重合（時移不改變振幅能量分佈）
%     - 純包絡延遲貢獻相位的「傾斜斜率」（群延遲 = tau）
%     - 純載波延遲貢獻相位的「常數平移項」（純水平線，群延遲 = 0）
%     - True Time Delay 為兩者相位的精確疊加，通過原點 (0, 0)

clear; clc; close all;

%% 1. 實驗參數設定
fs = 2000;                     % 取樣頻率 (Hz)
T  = 2.0;                      % 訊號時長 (秒)
N  = round(fs * T);            % 取樣點數
t  = (0:N-1) / fs;             % 時間向量 (秒)

fc = 80;                       % 載波頻率 (Hz)
Omega_c = 2 * pi * fc;         % 載波角頻率 (rad/s)
sigma = 0.04;                  % 高斯包絡半寬 (秒)
t0 = 0.4;                      % 基準波包中心時間 (秒)
tau = 0.4;                     % 時間延遲量 (秒)

fprintf('=== 延遲波包實驗參數 ===\n');
fprintf('取樣頻率 fs       : %d Hz\n', fs);
fprintf('載波頻率 fc       : %.1f Hz (Omega_c = %.1f rad/s)\n', fc, Omega_c);
fprintf('高斯包絡半寬 sigma: %.3f 秒\n', sigma);
fprintf('基準中心時間 t0   : %.2f 秒\n', t0);
fprintf('延遲量 tau        : %.2f 秒\n\n', tau);

%% 2. 訊號生成 (時域三種模式)
% 高斯包絡函數
gaussian_env = @(t_vec, center) exp(-(t_vec - center).^2 / (2 * sigma^2));

% 0. 基準訊號 (未延遲)
env_base = gaussian_env(t, t0);
x_base = env_base .* exp(1j * Omega_c * t);

% 1. 純包絡延遲 (Envelope-only Delay): 包絡移動到 t0 + tau，載波無延遲
env_delay = gaussian_env(t, t0 + tau);
x_env = env_delay .* exp(1j * Omega_c * t);

% 2. 純載波延遲 (Carrier-only Delay): 包絡留在 t0，載波延遲 tau (產生相移 -Omega_c * tau)
x_car = env_base .* exp(1j * Omega_c * (t - tau));

% 3. 兩者皆延遲 (True Time Delay, TTD): 包絡與載波同步延遲 tau
x_ttd = env_delay .* exp(1j * Omega_c * (t - tau));

%% 3. 傅立葉轉換 (FFT 計算)
Nfft = 8 * 2^nextpow2(N);      % 高解析度 FFT
f_axis = (-Nfft/2 : Nfft/2 - 1) * (fs / Nfft);

% 計算 FFT 置中
X_base = fftshift(fft(x_base, Nfft)) / N;
X_env  = fftshift(fft(x_env, Nfft)) / N;
X_car  = fftshift(fft(x_car, Nfft)) / N;
X_ttd  = fftshift(fft(x_ttd, Nfft)) / N;

% 振幅計算
mag_base = abs(X_base);
mag_env  = abs(X_env);
mag_car  = abs(X_car);
mag_ttd  = abs(X_ttd);

% 相位計算 (解纏繞)
% 選取載波附近的通帶 (In-band)，避免數值雜訊
bw_visual = 25; % 視覺化觀察頻寬 (+- 25 Hz)
in_band_idx = (f_axis >= fc - bw_visual) & (f_axis <= fc + bw_visual);
f_in_band = f_axis(in_band_idx);

phase_base = unwrap(angle(X_base(in_band_idx)));
phase_env  = unwrap(angle(X_env(in_band_idx)));
phase_car  = unwrap(angle(X_car(in_band_idx)));
phase_ttd  = unwrap(angle(X_ttd(in_band_idx)));

% 以基準訊號在 fc 的相位為基準做常數偏置歸零，凸顯相對延遲相位
phi_ref = interp1(f_in_band, phase_base, fc);
phase_env_rel = phase_env - phi_ref;
phase_car_rel = phase_car - phi_ref;
phase_ttd_rel = phase_ttd - phi_ref;

% 理論相位曲線
% 理論 1 (純包絡): -2*pi*(f - fc)*tau
theory_env = -2 * pi * (f_in_band - fc) * tau;
% 理論 2 (純載波): -2*pi*fc*tau (常數)
theory_car = -2 * pi * fc * tau * ones(size(f_in_band));
% 理論 3 (TTD)   : -2*pi*f*tau = theory_env + theory_car
theory_ttd = -2 * pi * (f_in_band - fc) * tau - 2 * pi * fc * tau;

% 數值群延遲: tau_g(f) = -1/(2*pi) * d(Phi)/df
df = f_in_band(2) - f_in_band(1);
gd_env = -1 / (2 * pi) * gradient(phase_env, df);
gd_car = -1 / (2 * pi) * gradient(phase_car, df);
gd_ttd = -1 / (2 * pi) * gradient(phase_ttd, df);

%% 4. 圖表繪製與輸出
output_dir = fileparts(mfilename('fullpath'));
if isempty(output_dir)
    output_dir = pwd;
end

fig = figure('Name', 'Wavepacket Three Delay Modes Comparison', ...
             'Position', [80, 80, 1200, 900], 'Color', 'w');

% --- 子圖 1: 時域實數波形對比 ---
subplot(2, 2, 1);
plot(t, real(x_base), 'Color', [0.7, 0.7, 0.7], 'LineWidth', 1.0, 'DisplayName', '基準訊號 (t_0=0.4s)');
hold on;
plot(t, real(x_env), 'Color', [0, 0.447, 0.741], 'LineWidth', 1.2, 'DisplayName', '1. 純包絡延遲 (\tau_e=\tau)');
plot(t, real(x_car), '--', 'Color', [0.85, 0.325, 0.098], 'LineWidth', 1.2, 'DisplayName', '2. 純載波延遲 (\tau_c=\tau)');
plot(t, real(x_ttd), ':', 'Color', [0.466, 0.674, 0.188], 'LineWidth', 1.5, 'DisplayName', '3. 兩者皆延遲 (TTD)');
grid on;
xlim([0.2, 1.2]);
xlabel('時間 Time (s)', 'FontSize', 10);
ylabel('振幅 Amplitude', 'FontSize', 10);
legend('Location', 'NorthEast', 'FontSize', 9);
title('1. 時域實數波形 (注意包絡中心位置與載波震盪相差)', 'FontSize', 11, 'FontWeight', 'bold');

% --- 子圖 2: 傅立葉振幅譜對比 ---
subplot(2, 2, 2);
plot(f_axis, mag_base, 'k-', 'LineWidth', 2.5, 'DisplayName', '基準訊號');
hold on;
plot(f_axis, mag_env, 'Color', [0, 0.447, 0.741], 'LineWidth', 1.5, 'DisplayName', '純包絡延遲');
plot(f_axis, mag_car, '--', 'Color', [0.85, 0.325, 0.098], 'LineWidth', 1.5, 'DisplayName', '純載波延遲');
plot(f_axis, mag_ttd, ':', 'Color', [0.466, 0.674, 0.188], 'LineWidth', 1.5, 'DisplayName', 'True Time Delay');
grid on;
xlim([fc - 30, fc + 30]);
xlabel('頻率 Frequency (Hz)', 'FontSize', 10);
ylabel('|X(f)| (Linear)', 'FontSize', 10);
legend('Location', 'NorthEast', 'FontSize', 9);
title('2. 頻譜振幅：三者嚴格重合！(時移不變性)', 'FontSize', 11, 'FontWeight', 'bold');

% --- 子圖 3: 相位譜對比 (核心亮點) ---
subplot(2, 2, 3);
plot(f_in_band, phase_env_rel, 'Color', [0, 0.447, 0.741], 'LineWidth', 2.0, ...
     'DisplayName', '純包絡延遲: 斜率 -2\pi\tau (在 f_c 過 0)');
hold on;
plot(f_in_band, phase_car_rel, 'Color', [0.85, 0.325, 0.098], 'LineWidth', 2.0, ...
     'DisplayName', '純載波延遲: 常數水平線 -\Omega_c\tau');
plot(f_in_band, phase_ttd_rel, 'Color', [0.466, 0.674, 0.188], 'LineWidth', 2.0, ...
     'DisplayName', 'True Time Delay: 兩者疊加 (斜率+截距)');
plot(f_in_band, theory_ttd, 'k--', 'LineWidth', 1.0, 'DisplayName', 'TTD 理論線: -2\pi f \tau');
xline(fc, 'k:', 'Label', sprintf('f_c = %d Hz', fc), 'LabelOrientation', 'horizontal');
grid on;
xlabel('頻率 Frequency (Hz)', 'FontSize', 10);
ylabel('相對相位 Relative Phase (rad)', 'FontSize', 10);
legend('Location', 'best', 'FontSize', 8.5);
title('3. 解纏繞相位譜：斜率 vs 水平線 vs 兩者疊加', 'FontSize', 11, 'FontWeight', 'bold');

% --- 子圖 4: 群延遲 (Group Delay) 對比 ---
subplot(2, 2, 4);
plot(f_in_band, gd_env, 'Color', [0, 0.447, 0.741], 'LineWidth', 2.0, 'DisplayName', sprintf('純包絡: \\tau_g = %.2fs', tau));
hold on;
plot(f_in_band, gd_car, 'Color', [0.85, 0.325, 0.098], 'LineWidth', 2.0, 'DisplayName', '\純載波: \tau_g = 0s');
plot(f_in_band, gd_ttd, ':', 'Color', [0.466, 0.674, 0.188], 'LineWidth', 2.5, 'DisplayName', sprintf('TTD: \\tau_g = %.2fs', tau));
yline(tau, 'k--', 'LineWidth', 0.8);
yline(0, 'k--', 'LineWidth', 0.8);
grid on;
ylim([-0.1, tau + 0.2]);
xlabel('頻率 Frequency (Hz)', 'FontSize', 10);
ylabel('群延遲 Group Delay (s)', 'FontSize', 10);
legend('Location', 'best', 'FontSize', 9);
title('4. 群延遲 \tau_g(f) = -1/(2\pi) d\Phi/df 驗證', 'FontSize', 11, 'FontWeight', 'bold');

exportgraphics(fig, fullfile(output_dir, 'wavepacket_three_delays_comparison.png'), 'Resolution', 200);

fprintf('三重延遲波包對比實驗完成！\n');
fprintf('輸出圖檔儲存於: %s\n', fullfile(output_dir, 'wavepacket_three_delays_comparison.png'));
