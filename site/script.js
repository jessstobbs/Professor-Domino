const downloads = {
  android: {
    label: "Download for Android",
    href: "https://github.com/jessstobbs/Professor-Domino/releases/latest/download/Professor-Domino-android.apk"
  },
  mac: {
    label: "Download for Mac",
    href: "https://github.com/jessstobbs/Professor-Domino/releases/latest/download/Professor-Domino-mac-arm64.dmg"
  },
  windows: {
    label: "Download for Windows",
    href: "https://github.com/jessstobbs/Professor-Domino/releases/latest/download/Professor-Domino-win-x64.exe"
  },
  linux: {
    label: "Download for Linux",
    href: "https://github.com/jessstobbs/Professor-Domino/releases/latest/download/Professor-Domino-linux-x86_64.AppImage"
  }
};

function detectPlatform() {
  const platform = `${navigator.userAgentData?.platform || navigator.platform || ""}`.toLowerCase();
  const userAgent = navigator.userAgent.toLowerCase();

  if (userAgent.includes("android")) return "android";
  if (platform.includes("win") || userAgent.includes("windows")) return "windows";
  if (platform.includes("linux") || userAgent.includes("linux")) return "linux";
  return "mac";
}

const downloadButton = document.querySelector("#downloadButton");
const download = downloads[detectPlatform()];

downloadButton.textContent = download.label;
downloadButton.href = download.href;
