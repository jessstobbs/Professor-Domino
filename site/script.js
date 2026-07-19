const downloads = {
  android: {
    label: "Download Android APK",
    ariaLabel: "Download Professor Domino Android APK",
    href: "https://github.com/jessstobbs/Professor-Domino/releases/latest/download/Professor-Domino-android.apk"
  },
  mac: {
    label: "Download macOS DMG",
    ariaLabel: "Download Professor Domino DMG for macOS Apple Silicon",
    href: "https://github.com/jessstobbs/Professor-Domino/releases/latest/download/Professor-Domino-mac-arm64.dmg"
  },
  windows: {
    label: "Download Windows installer",
    ariaLabel: "Download Professor Domino installer for Windows",
    href: "https://github.com/jessstobbs/Professor-Domino/releases/latest/download/Professor-Domino-win-x64.exe"
  },
  linux: {
    label: "Download Linux AppImage",
    ariaLabel: "Download Professor Domino AppImage for Linux",
    href: "https://github.com/jessstobbs/Professor-Domino/releases/latest/download/Professor-Domino-linux-x86_64.AppImage"
  }
};

function detectPlatform() {
  if (!window.navigator) return "android";

  const platform = `${navigator.userAgentData?.platform || navigator.platform || ""}`.toLowerCase();
  const userAgent = (navigator.userAgent || "").toLowerCase();

  if (userAgent.includes("android")) return "android";
  if (platform.includes("win") || userAgent.includes("windows")) return "windows";
  if (platform.includes("linux") || userAgent.includes("linux")) return "linux";
  return "mac";
}

const downloadButton = document.querySelector("#downloadButton");
const download = downloads[detectPlatform()];

if (downloadButton && download) {
  downloadButton.textContent = download.label;
  downloadButton.href = download.href;
  downloadButton.setAttribute("aria-label", download.ariaLabel);
}
