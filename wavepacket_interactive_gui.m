%% 延遲波包（Delayed Wavepacket at Omega_c）即時互動 GUI 介面
% 檔案名稱: wavepacket_interactive_gui.m
% 說明:
%   本腳本建立一個包含互動滑桿 (UI Sliders) 的 MATLAB 視窗，
%   允許使用者即時調整：
%     1. 載波頻率 Omega_c (fc)
%     2. 包絡寬度 Envelope Wideness (sigma_t) [新增]
%     3. 包絡延遲 tau_e
%     4. 載波延遲 tau_c
%     5. 勾選 [鎖定為 True Time Delay (tau_c = tau_e)]
%   圖表內含即時動態標示：
%     - 時域標示包絡寬度 sigma_t (1-sigma 區間) 與中心時間
%     - 頻域標示頻寬 sigma_f = 1/(2*pi*sigma_t) 與海森堡測不準乘積 sigma_t * sigma_f = 1/(2*pi)
%     - 包覆相位標示條紋週期 Delta f = 1/tau_e
%     - 解纏繞相位標示傾斜斜率 Slope = -2*pi*tau_e

function wavepacket_interactive_gui()
    % 基本設定
    fs = 2000;
    T = 2.0;
    N = round(fs * T);
    t = (0:N-1) / fs;
    Nfft = 8 * 2^nextpow2(N);
    f_axis = (-Nfft/2 : Nfft/2 - 1) * (fs / Nfft);
    t0 = 0.4;

    % 預設參數
    default_fc = 60;
    default_sigma_t = 0.05;   % 預設包絡寬度 50ms
    default_tau_e = 0.3;
    default_tau_c = 0.0;

    % 建立主視窗
    fig = figure('Name', 'Delayed Wavepacket Interactive Studio with Uncertainty Marks', ...
                 'Position', [80, 50, 1200, 850], 'Color', [0.96, 0.96, 0.98]);

    % 建立繪圖軸
    ax1 = subplot(2, 2, 1, 'Parent', fig);
    ax2 = subplot(2, 2, 2, 'Parent', fig);
    ax3 = subplot(2, 2, 3, 'Parent', fig);
    ax4 = subplot(2, 2, 4, 'Parent', fig);
    
    % 微調子圖位置留出下方雙排控制面板空間
    set(ax1, 'Position', [0.08, 0.59, 0.40, 0.34]);
    set(ax2, 'Position', [0.55, 0.59, 0.40, 0.34]);
    set(ax3, 'Position', [0.08, 0.18, 0.40, 0.33]);
    set(ax4, 'Position', [0.55, 0.18, 0.40, 0.33]);

    % 建立控制面板
    pnl = uipanel('Parent', fig, 'Position', [0.05, 0.01, 0.90, 0.14], ...
                  'BackgroundColor', 'w', 'Title', '即時參數控制面板 (拖動即時刷新)');

    % 第一排控制項: fc 與 sigma_t
    % 滑桿 1: 載波頻率 fc
    uicontrol('Parent', pnl, 'Style', 'text', 'Position', [15, 65, 140, 20], ...
              'String', '載波頻率 fc (Hz):', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    lbl_fc = uicontrol('Parent', pnl, 'Style', 'text', 'Position', [160, 65, 45, 20], ...
                       'String', sprintf('%.1f', default_fc), 'BackgroundColor', 'w', 'FontWeight', 'bold');
    sld_fc = uicontrol('Parent', pnl, 'Style', 'slider', 'Position', [15, 45, 190, 20], ...
                       'Min', 20, 'Max', 200, 'Value', default_fc);

    % 滑桿 2: 包絡寬度 sigma_t (Envelope Wideness)
    uicontrol('Parent', pnl, 'Style', 'text', 'Position', [230, 65, 140, 20], ...
              'String', '包絡寬度 \sigma_t (s):', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    lbl_sigma = uicontrol('Parent', pnl, 'Style', 'text', 'Position', [375, 65, 55, 20], ...
                          'String', sprintf('%.3f', default_sigma_t), 'BackgroundColor', 'w', 'FontWeight', 'bold', 'ForegroundColor', [0.7, 0, 0.7]);
    sld_sigma = uicontrol('Parent', pnl, 'Style', 'slider', 'Position', [230, 45, 190, 20], ...
                          'Min', 0.015, 'Max', 0.150, 'Value', default_sigma_t);

    % 第二排控制項: tau_e 與 tau_c
    % 滑桿 3: 包絡延遲 tau_e
    uicontrol('Parent', pnl, 'Style', 'text', 'Position', [15, 25, 140, 20], ...
              'String', '包絡延遲 \tau_e (s):', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    lbl_tau_e = uicontrol('Parent', pnl, 'Style', 'text', 'Position', [160, 25, 45, 20], ...
                          'String', sprintf('%.2f', default_tau_e), 'BackgroundColor', 'w', 'FontWeight', 'bold');
    sld_tau_e = uicontrol('Parent', pnl, 'Style', 'slider', 'Position', [15, 5, 190, 20], ...
                          'Min', 0.0, 'Max', 1.0, 'Value', default_tau_e);

    % 滑桿 4: 載波延遲 tau_c
    uicontrol('Parent', pnl, 'Style', 'text', 'Position', [230, 25, 140, 20], ...
              'String', '載波延遲 \tau_c (s):', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    lbl_tau_c = uicontrol('Parent', pnl, 'Style', 'text', 'Position', [375, 25, 45, 20], ...
                          'String', sprintf('%.2f', default_tau_c), 'BackgroundColor', 'w', 'FontWeight', 'bold');
    sld_tau_c = uicontrol('Parent', pnl, 'Style', 'slider', 'Position', [230, 5, 190, 20], ...
                          'Min', 0.0, 'Max', 1.0, 'Value', default_tau_c);

    % 快捷鍵: 鎖定 True Time Delay
    chk_ttd = uicontrol('Parent', pnl, 'Style', 'checkbox', 'Position', [450, 25, 250, 25], ...
                        'String', '鎖定為 True Time Delay (\tau_c = \tau_e)', ...
                        'BackgroundColor', 'w', 'FontWeight', 'bold', 'ForegroundColor', [0, 0.5, 0]);

    % 資訊徽章
    uicontrol('Parent', pnl, 'Style', 'text', 'Position', [720, 15, 330, 35], ...
              'String', sprintf('測不準原理物理極限: \\sigma_t \\cdot \\sigma_f = 1/(2\\pi) \\approx 0.1592\n拉動 \\sigma_t 觀察時域與頻域寬度的反比變動！'), ...
              'BackgroundColor', [1, 1, 0.9], 'FontWeight', 'bold', 'ForegroundColor', [0.2, 0.2, 0.2]);

    % 綁定回調函數
    set(sld_fc, 'Callback', @updatePlot);
    set(sld_sigma, 'Callback', @updatePlot);
    set(sld_tau_e, 'Callback', @updatePlot);
    set(sld_tau_c, 'Callback', @updatePlot);
    set(chk_ttd, 'Callback', @toggleTTD);

    % 首次繪製
    updatePlot();

    % --- 回調函數定義 ---
    function toggleTTD(~, ~)
        if get(chk_ttd, 'Value') == 1
            set(sld_tau_c, 'Enable', 'off');
            set(sld_tau_c, 'Value', get(sld_tau_e, 'Value'));
            set(lbl_tau_c, 'String', sprintf('%.2f', get(sld_tau_e, 'Value')));
        else
            set(sld_tau_c, 'Enable', 'on');
        end
        updatePlot();
    end

    function updatePlot(~, ~)
        fc_val = get(sld_fc, 'Value');
        sigma_t_val = get(sld_sigma, 'Value');
        tau_e_val = get(sld_tau_e, 'Value');
        if get(chk_ttd, 'Value') == 1
            tau_c_val = tau_e_val;
            set(sld_tau_c, 'Value', tau_c_val);
        else
            tau_c_val = get(sld_tau_c, 'Value');
        end

        % 更新文字標籤
        set(lbl_fc, 'String', sprintf('%.1f', fc_val));
        set(lbl_sigma, 'String', sprintf('%.3fs', sigma_t_val));
        set(lbl_tau_e, 'String', sprintf('%.2f', tau_e_val));
        set(lbl_tau_c, 'String', sprintf('%.2f', tau_c_val));

        % 計算訊號
        Omega_val = 2 * pi * fc_val;
        tc = t0 + tau_e_val; % 包絡中心時間
        env = exp(-(t - tc).^2 / (2 * sigma_t_val^2));
        carrier = exp(1j * Omega_val * (t - tau_c_val));
        x = env .* carrier;

        % FFT 計算
        X = fftshift(fft(x, Nfft)) / N;
        mag = abs(X);

        % 理論頻域寬度 (Heisenberg-Gabor Limit)
        sigma_f_theory = 1 / (2 * pi * sigma_t_val);

        % 相位分析
        visual_span = max(35, 4 * sigma_f_theory);
        idx_band = (f_axis >= fc_val - visual_span) & (f_axis <= fc_val + visual_span);
        f_sub = f_axis(idx_band);
        X_sub = X(idx_band);
        raw_phase = angle(X_sub);
        unwrapped_phase = unwrap(raw_phase);

        % 理論相位計算
        theory_phase = -2 * pi * (f_sub - fc_val) * tau_e_val - 2 * pi * fc_val * tau_c_val;

        % ========================================================
        % 1. 時域圖 (標示包絡中心與時域寬度 sigma_t)
        % ========================================================
        cla(ax1);
        plot(ax1, t, real(x), 'Color', [0, 0.447, 0.741, 0.6], 'LineWidth', 1.0);
        hold(ax1, 'on');
        plot(ax1, t, env, 'Color', [0.85, 0.325, 0.098], 'LineWidth', 1.8);
        plot(ax1, t, -env, 'Color', [0.85, 0.325, 0.098], 'LineWidth', 1.8);
        xline(ax1, tc, 'k:', 'LineWidth', 1.2);
        
        % 標示 1-sigma 時域寬度範圍 (y = exp(-0.5) 約 0.606 處)
        h_sigma = exp(-0.5);
        plot(ax1, [tc - sigma_t_val, tc + sigma_t_val], [h_sigma, h_sigma], 'm-', 'LineWidth', 2.2);
        plot(ax1, [tc - sigma_t_val, tc - sigma_t_val], [h_sigma - 0.08, h_sigma + 0.08], 'm-', 'LineWidth', 2.2);
        plot(ax1, [tc + sigma_t_val, tc + sigma_t_val], [h_sigma - 0.08, h_sigma + 0.08], 'm-', 'LineWidth', 2.2);
        text(ax1, tc, h_sigma + 0.15, sprintf('時域寬度 2\\sigma_t = %.3f s', 2 * sigma_t_val), ...
             'Color', [0.6, 0, 0.6], 'FontWeight', 'bold', 'FontSize', 10, 'HorizontalAlignment', 'center');
        
        grid(ax1, 'on');
        xlim(ax1, [0, T]);
        ylim(ax1, [-1.2, 1.3]);
        xlabel(ax1, '時間 Time (s)'); ylabel(ax1, '振幅 Amplitude');
        title(ax1, sprintf('1. 時域波包 (中心 t_c = %.2fs, \\sigma_t = %.3fs)', tc, sigma_t_val), 'FontWeight', 'bold');
        legend(ax1, '實數震盪', '包絡線 \pm w(t)', 'Location', 'NorthEast');

        % ========================================================
        % 2. 頻譜振幅 (標示中心頻率 fc、頻寬 sigma_f 與測不準乘積)
        % ========================================================
        cla(ax2);
        plot(ax2, f_axis, mag, 'Color', [0.466, 0.674, 0.188], 'LineWidth', 2.0);
        hold(ax2, 'on');
        grid(ax2, 'on');
        xlim(ax2, [0, min(fs/2, 250)]);
        
        peak_val = max(mag);
        xline(ax2, fc_val, 'k--', sprintf('fc = %.1f Hz', fc_val), 'LineWidth', 1.2);
        
        % 標示頻寬 2*sigma_f (在 peak * exp(-0.5) 處)
        h_mag_sigma = peak_val * exp(-0.5);
        plot(ax2, [fc_val - sigma_f_theory, fc_val + sigma_f_theory], [h_mag_sigma, h_mag_sigma], 'm-', 'LineWidth', 2.2);
        plot(ax2, [fc_val - sigma_f_theory, fc_val - sigma_f_theory], [h_mag_sigma - peak_val*0.06, h_mag_sigma + peak_val*0.06], 'm-', 'LineWidth', 2.2);
        plot(ax2, [fc_val + sigma_f_theory, fc_val + sigma_f_theory], [h_mag_sigma - peak_val*0.06, h_mag_sigma + peak_val*0.06], 'm-', 'LineWidth', 2.2);
        text(ax2, fc_val, h_mag_sigma + peak_val * 0.18, ...
             sprintf('頻寬 2\\sigma_f = 2/(2\\pi\\sigma_t) = %.1f Hz', 2 * sigma_f_theory), ...
             'Color', [0.6, 0, 0.6], 'FontWeight', 'bold', 'FontSize', 10, 'HorizontalAlignment', 'center');

        % 測不準原理乘積即時數值徽章
        text(ax2, 0.04, 0.88, ...
             sprintf('測不準乘積驗證:\n\\sigma_t \\times \\sigma_f = %.4f \\approx 1/(2\\pi)', sigma_t_val * sigma_f_theory), ...
             'Units', 'normalized', 'BackgroundColor', [1, 1, 0.8], 'EdgeColor', [0.6, 0.6, 0.6], ...
             'FontSize', 9.5, 'FontWeight', 'bold');

        xlabel(ax2, '頻率 Frequency (Hz)'); ylabel(ax2, '振幅 |X(f)|');
        title(ax2, sprintf('2. 頻譜振幅 (頻寬 \\sigma_f = %.2f Hz)', sigma_f_theory), 'FontWeight', 'bold');

        % ========================================================
        % 3. 包覆相位譜 (標示條紋週期 Delta f = 1/tau_e)
        % ========================================================
        cla(ax3);
        plot(ax3, f_sub, raw_phase, 'Color', [0.929, 0.694, 0.125], 'LineWidth', 1.2);
        grid(ax3, 'on');
        ylim(ax3, [-pi-0.3, pi+0.3]);
        yticks(ax3, [-pi, 0, pi]);
        yticklabels(ax3, {'-\pi', '0', '\pi'});
        
        if tau_e_val > 0.05
            fringe_period = 1 / tau_e_val;
            title_str = sprintf('3. 包覆相位 (條紋週期 \\Delta f = 1/\\tau_e = %.1f Hz)', fringe_period);
        else
            title_str = '3. 包覆相位 (\\tau_e \\approx 0 時幾乎無鋸齒)';
        end
        xlabel(ax3, '頻率 Frequency (Hz)'); ylabel(ax3, '包覆相位 (rad)');
        title(ax3, title_str, 'FontWeight', 'bold');

        % ========================================================
        % 4. 解纏繞相位譜 (標示線性斜率 Slope = -2*pi*tau_e)
        % ========================================================
        cla(ax4);
        plot(ax4, f_sub, unwrapped_phase, 'Color', [0.494, 0.184, 0.556], 'LineWidth', 2.2);
        hold(ax4, 'on');
        plot(ax4, f_sub, theory_phase - (theory_phase(round(end/2)) - unwrapped_phase(round(end/2))), ...
             'k--', 'LineWidth', 1.0);
        xline(ax4, fc_val, 'k:', 'LineWidth', 1.0);
        grid(ax4, 'on');
        xlabel(ax4, '頻率 Frequency (Hz)'); ylabel(ax4, '解纏繞相位 (rad)');
        slope_val = -2 * pi * tau_e_val;
        title(ax4, sprintf('4. 解纏繞相位 (斜率 = -2\\pi\\tau_e = %.2f rad/Hz)', slope_val), 'FontWeight', 'bold');
        legend(ax4, '測量相位', '理論直線', 'Location', 'best');
    end
end
