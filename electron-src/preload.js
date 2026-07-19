const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("domino", {
  assetsPath: () => ipcRenderer.invoke("assets-path"),
  getQuotes: () => ipcRenderer.invoke("get-quotes"),
  saveQuotes: (quotes) => ipcRenderer.invoke("save-quotes", quotes),
  showRandomQuote: () => ipcRenderer.send("show-random-quote"),
  onShowQuote: (callback) => ipcRenderer.on("show-quote", (_event, quote) => callback(quote)),
  onOpenEditor: (callback) => ipcRenderer.on("open-editor", callback)
});
