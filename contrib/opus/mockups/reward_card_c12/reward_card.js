// The two-wreck fixture follows the Council's seed 121 reward picture.
// The four-wreck fixture adds two illustrative credit-only rows. No game logic runs here.
const wrecks = [
  {
    name: "Cordon destroyer", hull: "Destroyer", sprite: "H8_23",
    cause: "Cut in two by a lance from the Bright Censure.",
    refit: "Lance focusing crystal", benefit: "Lance damage +25%", credits: 28,
  },
  {
    name: "Meridian picket", hull: "Frigate", sprite: "H7_23",
    cause: "Cut in two by a lance from the Bright Censure.",
    refit: "Battery loaders", benefit: "Battery weapons fire +1 shot", credits: 19,
  },
  {
    name: "Cordon cruiser", hull: "Cruiser", sprite: "H9_23",
    cause: "Blown apart. No refit survived.",
    credits: 46,
  },
  {
    name: "Line battleship", hull: "Battleship", sprite: "H10_23",
    cause: "Melted by corrosive fire. No refit survived.",
    credits: 58,
  },
];

const params = new URLSearchParams(location.search);
const layout = params.get("layout") === "register" ? "register" : "ledger";
const count = params.get("wrecks") === "4" ? 4 : 2;
const rev = params.get("rev") || "local preview";
const get = (id) => document.getElementById(id);
const num = (value) => `<span class="figure">${value}</span>`;

document.querySelector(".card").dataset.layout = layout;
get("review-label").textContent = `C12 mock-up, run 3, ${rev}`;
get("review-option").textContent =
  `${layout === "ledger" ? "A / Wreck ledger" : "B / Hull register"} / ${count} wrecks`;
get("result").innerHTML = `Enemy fleet destroyed in ${num(count === 2 ? 5 : 7)} rounds.`;
get("credits").textContent = count === 2 ? "+37" : "+74";
get("wreck-count").innerHTML = `${num(count)} wrecks`;

let activeWreck = 0;
let activeChoice = "refit";

const spriteRoot = "../../../../godot/ui/battle/icons/ships/";
const list = get("wreck-list");
wrecks.slice(0, count).forEach((wreck, index) => {
  const item = document.createElement("li");
  item.innerHTML = `<button class="wreck" type="button" aria-pressed="false" aria-keyshortcuts="${index + 1}">
    <span class="mark" aria-hidden="true"></span>
    <img class="hull" src="${spriteRoot}${wreck.sprite}.png" alt="">
    <span class="identity"><span class="wreck-name">${wreck.name}</span>
      <span class="wreck-class">${wreck.hull}</span></span>
    <span class="availability quiet">${wreck.refit ? "Refit or credits" : "Credits only"}</span>
    <kbd class="wreck-key">${index + 1}</kbd>
  </button>`;
  item.firstElementChild.addEventListener("click", () => selectWreck(index));
  list.append(item);
});

function selectWreck(index) {
  activeWreck = index;
  const wreck = wrecks[index];
  activeChoice = wreck.refit ? "refit" : "credits";
  Array.from(list.children).forEach((item, i) => {
    item.firstElementChild.setAttribute("aria-pressed", i === index);
  });
  get("wreck-title").textContent = wreck.name;
  get("wreck-cause").textContent = wreck.cause;
  const options = [];
  if (wreck.refit) {
    options.push(["refit", "Strip for refit", wreck.benefit.replace(/\+\d+%?/g, num), "R"]);
  }
  options.push(["credits", "Strip for credits", `${num("+" + wreck.credits)} credits`, "C"]);
  const choices = get("choices");
  choices.replaceChildren();
  options.forEach(([id, label, value, key]) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "choice";
    button.dataset.choice = id;
    button.setAttribute("aria-keyshortcuts", key);
    button.innerHTML = `<span class="mark" aria-hidden="true"></span>
      <span><span class="choice-label">${label}</span> <span class="choice-value">${value}</span></span>
      <kbd>${key}</kbd>`;
    button.addEventListener("click", () => selectChoice(id));
    choices.append(button);
  });
  selectChoice(activeChoice);
}

function selectChoice(id) {
  const choices = [...get("choices").children];
  if (!choices.some((button) => button.dataset.choice === id)) return;
  activeChoice = id;
  choices.forEach((button) => button.setAttribute("aria-pressed", button.dataset.choice === id));
  const wreck = wrecks[activeWreck];
  get("selection").innerHTML = id === "refit"
    ? `${wreck.refit} goes to the hold.`
    : `${num("+" + wreck.credits)} credits go to your fleet.`;
}

get("confirm").addEventListener("click", () => {
  get("selection").textContent = "Preview only. No salvage was taken.";
});
document.addEventListener("keydown", (event) => {
  if (event.metaKey || event.ctrlKey || event.altKey || event.repeat) return;
  if (/^[1-4]$/.test(event.key) && Number(event.key) <= count) selectWreck(Number(event.key) - 1);
  if (event.key.toLowerCase() === "r") selectChoice("refit");
  if (event.key.toLowerCase() === "c") selectChoice("credits");
  if (event.key === "Enter") {
    event.preventDefault();
    get("confirm").click();
  }
});

selectWreck(0);
