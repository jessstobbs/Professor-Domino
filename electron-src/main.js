const { app, BrowserWindow, Menu, Tray, ipcMain, shell, nativeImage, screen } = require("electron");
const fs = require("fs");
const path = require("path");

const isDev = !app.isPackaged;
const appRoot = isDev ? path.join(__dirname, "..") : process.resourcesPath;
const defaultQuotesPath = path.join(appRoot, "quotes.json");
const assetsPath = path.join(appRoot, "assets");
const isSmokeTest = process.argv.includes("--smoke-test");

let companionWindow;
let tray;
let quotes = [];
let recentQuoteIndexes = [];
let intervalMinutes = 180;
let quoteTimer;
let companionVisible = true;
let lastMenuQuote = "Warming up...";

const fallbackQuotes = [
  { text: "Begin anywhere.", author: "John Cage" },
  { text: "The work teaches you how to do it.", author: null },
  { text: "Small steps still move the whole day.", author: null }
];

function userQuotesPath() {
  return path.join(app.getPath("documents"), "Professor Domino", "quotes.json");
}

function ensureEditableQuotesFile() {
  const target = userQuotesPath();
  if (fs.existsSync(target)) return;
  fs.mkdirSync(path.dirname(target), { recursive: true });
  if (fs.existsSync(defaultQuotesPath)) {
    fs.copyFileSync(defaultQuotesPath, target);
  } else {
    fs.writeFileSync(target, JSON.stringify(fallbackQuotes, null, 2));
  }
}

function normalizeQuotes(nextQuotes) {
  if (!Array.isArray(nextQuotes)) return fallbackQuotes;
  return nextQuotes
    .map((quote) => ({
      text: typeof quote?.text === "string" ? quote.text.trim() : "",
      author: typeof quote?.author === "string" && quote.author.trim() ? quote.author.trim() : null
    }))
    .filter((quote) => quote.text);
}

function loadQuotes() {
  ensureEditableQuotesFile();
  try {
    quotes = normalizeQuotes(JSON.parse(fs.readFileSync(userQuotesPath(), "utf8")));
  } catch (error) {
    quotes = fallbackQuotes;
  }
}

function saveQuotes(nextQuotes) {
  quotes = normalizeQuotes(nextQuotes);
  ensureEditableQuotesFile();
  fs.writeFileSync(userQuotesPath(), JSON.stringify(quotes, null, 2));
  rebuildMenu();
}

function randomQuote() {
  if (!quotes.length) return { text: "Add a few quotes and I will keep you company.", author: null };
  const available = quotes.map((_, index) => index).filter((index) => !recentQuoteIndexes.includes(index));
  const pool = available.length ? available : quotes.map((_, index) => index);
  const index = pool[Math.floor(Math.random() * pool.length)] || 0;
  recentQuoteIndexes.push(index);
  const maxRecent = Math.min(5, Math.max(1, quotes.length - 1));
  while (recentQuoteIndexes.length > maxRecent) recentQuoteIndexes.shift();
  return quotes[index];
}

function quoteLabel(quote) {
  const text = typeof quote?.text === "string" && quote.text.trim() ? quote.text.trim() : "Add a few quotes and I will keep you company.";
  const author = typeof quote?.author === "string" && quote.author.trim() ? ` - ${quote.author.trim()}` : "";
  return `"${text}"${author}`;
}

function showQuoteNow() {
  const quote = randomQuote();
  lastMenuQuote = quoteLabel(quote);
  rebuildMenu();
  companionWindow?.webContents.send("show-quote", quote);
}

function scheduleTimer() {
  if (quoteTimer) clearInterval(quoteTimer);
  quoteTimer = setInterval(showQuoteNow, intervalMinutes * 60 * 1000);
}

function createCompanionWindow() {
  const display = screen.getPrimaryDisplay().workArea;
  const side = Math.min(420, Math.max(300, Math.floor(display.height * 0.42)));
  companionWindow = new BrowserWindow({
    width: side,
    height: side,
    x: display.x + display.width - side - 36,
    y: display.y + display.height - side - 48,
    frame: false,
    transparent: true,
    resizable: false,
    skipTaskbar: true,
    alwaysOnTop: true,
    hasShadow: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  companionWindow.setAlwaysOnTop(true, "floating");
  companionWindow.loadFile(path.join(__dirname, "renderer.html"));

  if (isSmokeTest) {
    companionWindow.webContents.once("did-finish-load", () => {
      companionWindow.webContents.send("show-quote", randomQuote());
      setTimeout(() => app.quit(), 500);
    });
  }
}

function openEditor() {
  if (!companionWindow) return;
  companionVisible = true;
  companionWindow.show();
  companionWindow.webContents.send("open-editor");
  rebuildMenu();
}

function trayImage() {
  const image = nativeImage.createFromPath(path.join(assetsPath, "cat_companion.png"));
  return image.resize({ width: 22, height: 22 });
}

function rebuildMenu() {
  const intervalItems = [
    ["30 Minutes", 30],
    ["1 Hour", 60],
    ["3 Hours", 180],
    ["6 Hours", 360]
  ].map(([label, minutes]) => ({
    label,
    type: "radio",
    checked: intervalMinutes === minutes,
    click: () => {
      intervalMinutes = minutes;
      scheduleTimer();
      rebuildMenu();
    }
  }));

  const menu = Menu.buildFromTemplate([
    { label: lastMenuQuote, enabled: false },
    { type: "separator" },
    { label: "Say Something Now", accelerator: "CmdOrCtrl+S", click: showQuoteNow },
    { label: "Add Quote", accelerator: "CmdOrCtrl+A", click: openEditor },
    {
      label: companionVisible ? "Hide Companion" : "Show Companion",
      accelerator: "CmdOrCtrl+H",
      click: () => {
        companionVisible = !companionVisible;
        companionVisible ? companionWindow.show() : companionWindow.hide();
        rebuildMenu();
      }
    },
    { label: "Every", submenu: intervalItems },
    { type: "separator" },
    { label: "Edit Quotes", accelerator: "CmdOrCtrl+E", click: () => shell.openPath(userQuotesPath()) },
    {
      label: "Reload Quotes",
      accelerator: "CmdOrCtrl+R",
      click: () => {
        loadQuotes();
        lastMenuQuote = quoteLabel(randomQuote());
        rebuildMenu();
      }
    },
    { type: "separator" },
    { label: "Quit", accelerator: "CmdOrCtrl+Q", click: () => app.quit() }
  ]);

  tray?.setContextMenu(menu);
}

app.whenReady().then(() => {
  loadQuotes();
  createCompanionWindow();
  tray = new Tray(trayImage());
  tray.setToolTip("Professor Domino");
  lastMenuQuote = quoteLabel(randomQuote());
  rebuildMenu();
  scheduleTimer();
});

ipcMain.handle("assets-path", () => assetsPath);
ipcMain.handle("get-quotes", () => quotes);
ipcMain.handle("save-quotes", (_event, nextQuotes) => saveQuotes(nextQuotes));
ipcMain.on("move-window", (_event, delta) => {
  if (!companionWindow || !delta || !Number.isFinite(delta.x) || !Number.isFinite(delta.y)) return;
  const [x, y] = companionWindow.getPosition();
  companionWindow.setPosition(Math.round(x + delta.x), Math.round(y + delta.y));
});
ipcMain.on("show-random-quote", showQuoteNow);

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
