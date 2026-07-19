const images = {
  normal: "../assets/cat_companion.png",
  hover: "../assets/cat_companion_hover.png",
  nose: "../assets/cat_companion_nose_hover.png",
  ears: "../assets/cat_companion_idle_ears_back.png",
  wink: "../assets/cat_companion_idle_wink.png",
  editor: "../assets/cat_companion_editor_open.png"
};

const dominoButton = document.querySelector("#dominoButton");
const dominoImage = document.querySelector("#dominoImage");
const bubble = document.querySelector("#bubble");
const quoteText = document.querySelector("#quoteText");
const paw = document.querySelector("#paw");
const editor = document.querySelector("#editor");
const quoteList = document.querySelector("#quoteList");
const addQuoteButton = document.querySelector("#addQuote");
const editorForm = document.querySelector("#editorForm");

let quotes = [];
let bubbleTimer;
let quoteShownForHover = false;
let dragStart;
let didDrag = false;

dominoImage.src = images.normal;
paw.src = "../assets/pawprint.svg";

function setDominoImage(src) {
  dominoImage.src = src;
}

function showQuote(quote) {
  const text = typeof quote?.text === "string" && quote.text.trim() ? quote.text.trim() : "Add a few quotes and I will keep you company.";
  const author = typeof quote?.author === "string" && quote.author.trim() ? `\n- ${quote.author.trim()}` : "";
  quoteText.textContent = `${text}${author}`;
  paw.hidden = quoteText.textContent.length > 110;
  bubble.classList.add("visible");
  clearTimeout(bubbleTimer);
  bubbleTimer = setTimeout(hideQuote, 7000);
}

function hideQuote() {
  bubble.classList.remove("visible");
}

function renderEditor() {
  quoteList.replaceChildren();
  quotes.forEach((quote, index) => {
    const row = document.createElement("section");
    row.className = "quoteRow";

    const textArea = document.createElement("textarea");
    textArea.setAttribute("aria-label", "Quote text");
    textArea.value = quote.text || "";

    const authorInput = document.createElement("input");
    authorInput.setAttribute("aria-label", "Author");
    authorInput.placeholder = "Author (optional)";
    authorInput.value = quote.author || "";

    const removeButton = document.createElement("button");
    removeButton.type = "button";
    removeButton.textContent = "Remove";
    removeButton.addEventListener("click", () => {
      quotes.splice(index, 1);
      renderEditor();
    });

    row.append(textArea, authorInput, removeButton);
    quoteList.append(row);
  });
}

async function openEditor() {
  quotes = await window.domino.getQuotes();
  renderEditor();
  setDominoImage(images.editor);
  if (!editor.open) editor.showModal();
}

function clearDrag() {
  dragStart = null;
}

dominoButton.addEventListener("mousedown", (event) => {
  if (event.button !== 0 || editor.open) return;
  dragStart = { x: event.screenX, y: event.screenY };
  didDrag = false;
});

window.addEventListener("mousemove", (event) => {
  if (!dragStart) return;
  const delta = { x: event.screenX - dragStart.x, y: event.screenY - dragStart.y };
  if (Math.abs(delta.x) + Math.abs(delta.y) < 3) return;
  didDrag = true;
  dragStart = { x: event.screenX, y: event.screenY };
  window.domino.moveWindow(delta);
});

window.addEventListener("mouseup", clearDrag);
window.addEventListener("blur", clearDrag);

dominoButton.addEventListener("mouseenter", () => {
  setDominoImage(images.hover);
  if (!quoteShownForHover) {
    quoteShownForHover = true;
    window.domino.showRandomQuote();
  }
});

dominoButton.addEventListener("mouseleave", () => {
  quoteShownForHover = false;
  if (!editor.open) setDominoImage(images.normal);
  hideQuote();
});

dominoButton.addEventListener("click", () => {
  if (didDrag) {
    didDrag = false;
    return;
  }
  window.domino.showRandomQuote();
});

dominoButton.addEventListener("dblclick", openEditor);

addQuoteButton.addEventListener("click", () => {
  quotes.push({ text: "", author: null });
  renderEditor();
});

editorForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  quotes = [...quoteList.querySelectorAll(".quoteRow")]
    .map((row) => ({
      text: row.querySelector("textarea").value.trim(),
      author: row.querySelector("input").value.trim() || null
    }))
    .filter((quote) => quote.text);
  await window.domino.saveQuotes(quotes);
  editor.close();
  setDominoImage(images.normal);
});

editor.addEventListener("close", () => {
  setDominoImage(images.normal);
});

window.domino.onShowQuote(showQuote);
window.domino.onOpenEditor(openEditor);

setInterval(() => {
  if (editor.open || bubble.classList.contains("visible")) return;
  setDominoImage(images.ears);
  setTimeout(() => setDominoImage(images.normal), 90);
  setTimeout(() => setDominoImage(images.ears), 150);
  setTimeout(() => setDominoImage(images.normal), 240);
}, 11000);

setInterval(() => {
  if (editor.open || bubble.classList.contains("visible")) return;
  setDominoImage(images.wink);
  setTimeout(() => setDominoImage(images.normal), 650);
}, 29000);
