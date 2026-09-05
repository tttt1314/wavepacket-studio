# 延遲波包（Delayed Wavepacket at \(\Omega_c\)）三重延遲機制深度對比實驗

本實驗目錄探討高斯波包在調整載波頻率 \(\Omega_c\) 以及三種時間延遲機制下的頻譜振幅與相位演變。

---

## 數學模型與物理推導

設訊號模型為：
$$x(t) = w(t - \tau_e) \exp\left(j \Omega_c (t - \tau_c)\right)$$

其中：
- $w(t) = \exp\left(-\frac{t^2}{2\sigma^2}\right)$ 為高斯包絡
- $\Omega_c = 2\pi f_c$ 為載波頻率
- $\tau_e$ 為包絡延遲（Envelope Delay）
- $\tau_c$ 為載波延遲（Carrier tone Delay）

### 頻譜三大機制對比

1. **純包絡延遲（$\tau_e = \tau, \tau_c = 0$）**：
   - 頻譜：$X(f) = W(f - f_c) e^{-j 2\pi (f - f_c) \tau}$
   - 相位：$\Phi(f) = -2\pi(f - f_c)\tau$
   - 特徵：通過點 $(f_c, 0)$，在載波中心頻率處相位恆為 0，斜率為 $-2\pi\tau$，群延遲為 $\tau$。

2. **純載波延遲（$\tau_e = 0, \tau_c = \tau$）**：
   - 頻譜：$X(f) = W(f - f_c) e^{-j 2\pi f_c \tau}$
   - 相位：$\Phi(f) = -2\pi f_c \tau = -\Omega_c \tau$（常數）
   - 特徵：水平直線，斜率為 0，群延遲為 0，僅產生固定相移。

3. **兩者皆延遲（True Time Delay, $\tau_e = \tau, \tau_c = \tau$）**：
   - 頻譜：$X(f) = W(f - f_c) e^{-j 2\pi f \tau}$
   - 相位：$\Phi(f) = -2\pi f \tau = \Phi_{\text{Envelope}} + \Phi_{\text{Carrier}}$
   - 特徵：通過原點 $(0, 0)$，斜率為 $-2\pi\tau$，群延遲為 $\tau$。

4. **振幅譜 $|X(f)|$**：
   - 三者的振幅譜完全重合，不受任何時間延遲影響；調整 $\Omega_c$ 時，振幅譜在頻率軸上產生剛體平移。

---

## 檔案清單
- `wavepacket_three_delays_experiment.m`：自動化對比腳本，生成時域、振幅、解纏繞相位與群延遲對比圖。
- `wavepacket_interactive_gui.m`：MATLAB 即時互動視窗，支援動態拖曳 `Omega_c`、`tau_e`、`tau_c` 滑桿。
- `wavepacket_three_delays_comparison.png`：高清輸出對比圖。
