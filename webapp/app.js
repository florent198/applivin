const STORAGE_KEY = "applivin_web_cards_v1";

const aromaCategories = {
  fleur: { title: "🌸 FLEUR", aromas: ["Iris", "Pivoine", "Fleur de sureau", "Acacia", "Lilas", "Jasmin", "Chevrefeuille", "Violette", "Lavande", "Rose", "Pot-pourri", "Hibiscus"] },
  "fruit-pepins": { title: "🍎 FRUITS A PEPINS", aromas: ["Coing", "Pomme", "Poire", "Nectarine", "Peche", "Abricot", "Kaki"] },
  "fruit-tropicaux": { title: "🥭 FRUITS TROPICAUX", aromas: ["Ananas", "Mangue", "Goyave", "Kiwi", "Litchi", "Chewing-gum"] },
  "fruits-rouges": { title: "🍓 FRUITS ROUGES", aromas: ["Cranberry", "Prune Rouge", "Grenade", "Cerise aigre", "Fraise", "Cerise", "Framboise"] },
  "fruits-noirs": { title: "🍒 FRUITS NOIRS", aromas: ["Mure de Boysen", "Cassis", "Cerise Noire", "Prune", "Mure", "Myrtille", "Olive"] },
  "fruits-secs": { title: "🌰 FRUITS SECS", aromas: ["Raisin", "Figue", "Datte", "Fruit confit"] },
  pourriture: { title: "🍯 POURRITURE NOBLE", aromas: ["Cire d'abeille", "Gingembre", "Miel"] },
  epice: { title: "🌶 EPICE", aromas: ["Poivre blanc", "Poivre rouge", "Poivre noir", "Cannelle", "Anis", "Les 5 parfums chinois", "Fenouil", "Eucalyptus", "Menthe", "Thym"] },
  vegetal: { title: "🌿 VEGETAL", aromas: ["The Noir", "Tomate Sechee", "Tomate", "Amande verte", "Piment", "Poivron", "Groseille", "Feuilles de Tomate", "Herbe"] },
  terreux: { title: "🌍 TERREUX", aromas: ["Petrole", "Roches volcaniques", "Betterave Rouge", "Terreau", "Gravier humide", "Ardoise", "Argile"] },
  microbien: { title: "🧫 MICROBIEN", aromas: ["Champignon", "Truffe", "Levure", "Levain", "Creme", "Beurre"] },
  "elevage-bois": { title: "🪵 ELEVAGE BOIS", aromas: ["Aneth", "Fumee", "Boite a cigares", "Epices de cuisson", "Noix de coco", "Vanille"] },
  "vieillissement-general": { title: "⏳ VIEILLISSEMENT", aromas: ["Cuir", "Cacao", "Cafe", "Tabac", "Noix", "Fruits secs"] },
  bouchonne: { title: "🍄 BOUCHONNE", aromas: ["Chien Moisi", "Carton moisi"] },
  soufre: { title: "❌ SOUFRE", aromas: ["Urine de chat", "Oignon", "Ail", "Boites d'allumettes", "Caoutchouc brule", "Oeuf Pourri", "Viande Sechee"] },
  brett: { title: "❌ BRETT", aromas: ["Fumier de cheval", "Selle de cuir", "Pansement adhesif", "Cardamome noire"] },
  cuit: { title: "❌ CUIT", aromas: ["Fruit denoyaute", "Caramel"] },
  acidite: { title: "🍋 ACIDITE", aromas: ["Balsamique", "Vinaigre"] },
  agrumes: { title: "🍋 AGRUMES", aromas: ["Citron vert", "Citron", "Pamplemousse", "Orange", "Marmelade"] }
};

const knownShapeIds = new Set(Object.keys(aromaCategories));

let cards = loadCards();
let editingId = null;
let pendingImageData = null;
let lastMainView = "home";

const views = {
  home: document.getElementById("view-home"),
  editor: document.getElementById("view-editor"),
  saved: document.getElementById("view-saved"),
  wheel: document.getElementById("view-wheel"),
  guide: document.getElementById("view-guide")
};

const savedCountEl = document.getElementById("saved-count");
const savedListEl = document.getElementById("saved-list");
const form = document.getElementById("wine-form");
const ratingOutput = document.getElementById("rating-output");
const photoPreview = document.getElementById("photo-preview");
const editorTitle = document.getElementById("editor-title");
const toastEl = document.getElementById("toast");
const aromaTitleEl = document.getElementById("aroma-title");
const aromaListEl = document.getElementById("aroma-list");
const guideTitleEl = document.getElementById("guide-title");
const guideContentEl = document.getElementById("guide-content");

wireNavigation();
wireButtons();
wireForm();
renderSavedCount();
renderSavedList();
loadWheel();

function wireNavigation() {
  const navButtons = Array.from(document.querySelectorAll(".nav-btn"));
  navButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const viewName = button.dataset.view;
      if (viewName === "home") {
        showView("home");
      }
      if (viewName === "wheel") {
        showView("wheel");
      }
      navButtons.forEach((btn) => btn.classList.remove("active"));
      button.classList.add("active");
    });
  });
}

function wireButtons() {
  document.getElementById("btn-create").addEventListener("click", () => {
    startNewCard();
    showView("editor");
  });

  document.getElementById("btn-saved").addEventListener("click", () => {
    renderSavedList();
    showView("saved");
  });

  document.getElementById("btn-cancel-edit").addEventListener("click", () => {
    resetEditor();
    showView("home");
  });

  document.querySelectorAll(".guide-btn").forEach((button) => {
    button.addEventListener("click", () => openGuide(button.dataset.guide));
  });

  document.getElementById("btn-back-guide").addEventListener("click", () => {
    showView(lastMainView);
  });
}

function wireForm() {
  form.elements.rating.addEventListener("input", (event) => {
    ratingOutput.value = event.target.value;
  });

  form.elements.photo.addEventListener("change", async (event) => {
    const file = event.target.files[0];
    if (!file) {
      pendingImageData = null;
      photoPreview.classList.add("hidden");
      return;
    }
    pendingImageData = await readFileAsDataURL(file);
    photoPreview.src = pendingImageData;
    photoPreview.classList.remove("hidden");
  });

  form.addEventListener("submit", (event) => {
    event.preventDefault();

    const payload = {
      id: editingId || crypto.randomUUID(),
      name: form.elements.name.value.trim() || "Nom du vin",
      vintage: form.elements.vintage.value.trim(),
      producer: form.elements.producer.value.trim(),
      appellation: form.elements.appellation.value.trim(),
      grapes: form.elements.grapes.value.trim(),
      color: form.elements.color.value,
      length: form.elements.length.value,
      rating: Number(form.elements.rating.value),
      notes: form.elements.notes.value.trim(),
      imageData: pendingImageData
    };

    if (editingId) {
      const index = cards.findIndex((card) => card.id === editingId);
      if (index !== -1) {
        if (!payload.imageData) {
          payload.imageData = cards[index].imageData || null;
        }
        cards[index] = payload;
      }
      showToast("Fiche mise a jour");
    } else {
      cards.push(payload);
      showToast("Fiche enregistree");
    }

    saveCards();
    renderSavedCount();
    renderSavedList();
    resetEditor();
    showView("saved");
  });
}

function showView(name) {
  Object.entries(views).forEach(([key, node]) => {
    node.classList.toggle("active", key === name);
  });
  if (name === "home" || name === "wheel") {
    lastMainView = name;
  }
}

function startNewCard() {
  editingId = null;
  editorTitle.textContent = "Nouvelle fiche";
  form.reset();
  form.elements.rating.value = "4";
  ratingOutput.value = "4";
  pendingImageData = null;
  photoPreview.classList.add("hidden");
}

function editCard(id) {
  const card = cards.find((entry) => entry.id === id);
  if (!card) {
    return;
  }

  editingId = card.id;
  editorTitle.textContent = "Modifier la fiche";
  form.elements.name.value = card.name || "";
  form.elements.vintage.value = card.vintage || "";
  form.elements.producer.value = card.producer || "";
  form.elements.appellation.value = card.appellation || "";
  form.elements.grapes.value = card.grapes || "";
  form.elements.color.value = card.color || "rouge";
  form.elements.length.value = card.length || "court";
  form.elements.rating.value = String(card.rating || 4);
  ratingOutput.value = String(card.rating || 4);
  form.elements.notes.value = card.notes || "";

  pendingImageData = card.imageData || null;
  if (pendingImageData) {
    photoPreview.src = pendingImageData;
    photoPreview.classList.remove("hidden");
  } else {
    photoPreview.classList.add("hidden");
  }

  showView("editor");
}

function removeCard(id) {
  cards = cards.filter((card) => card.id !== id);
  saveCards();
  renderSavedCount();
  renderSavedList();
  showToast("Fiche supprimee");
}

function renderSavedCount() {
  savedCountEl.textContent = String(cards.length);
}

function renderSavedList() {
  if (!cards.length) {
    savedListEl.innerHTML = "<p>Aucune fiche enregistree.</p>";
    return;
  }

  savedListEl.innerHTML = "";
  cards
    .slice()
    .reverse()
    .forEach((card) => {
      const item = document.createElement("article");
      item.className = "saved-item";

      const imageMarkup = card.imageData
        ? `<img class=\"photo-preview\" src=\"${card.imageData}\" alt=\"Photo ${escapeHtml(card.name)}\" />`
        : "";

      item.innerHTML = `
        <h4>${escapeHtml(card.name || "Nom du vin")}</h4>
        <p>${escapeHtml(card.vintage || "Millesime non renseigne")}</p>
        <p>${escapeHtml(card.appellation || "Appellation non renseignee")}</p>
        <p>Note: ${card.rating || 4}/5</p>
        ${imageMarkup}
        <div class="saved-actions">
          <button class="btn" data-edit="${card.id}">Modifier</button>
          <button class="btn" data-delete="${card.id}">Supprimer</button>
        </div>
      `;
      savedListEl.appendChild(item);
    });

  savedListEl.querySelectorAll("[data-edit]").forEach((button) => {
    button.addEventListener("click", () => editCard(button.dataset.edit));
  });

  savedListEl.querySelectorAll("[data-delete]").forEach((button) => {
    button.addEventListener("click", () => removeCard(button.dataset.delete));
  });
}

async function loadWheel() {
  const wrap = document.getElementById("wheel-wrap");
  try {
    const response = await fetch("./assets/roue-des-aromes-2.svg");
    const svgRaw = await response.text();
    wrap.innerHTML = svgRaw;
    const svg = wrap.querySelector("svg");
    if (!svg) {
      return;
    }

    svg.querySelectorAll("[id]").forEach((element) => {
      if (!knownShapeIds.has(element.id)) {
        return;
      }
      bindTap(element, element.id);
      element
        .querySelectorAll("path, polygon, circle, ellipse")
        .forEach((child) => {
          ensureHitArea(child);
          bindTap(child, element.id);
        });
    });

    wrap.addEventListener("pointerdown", (event) => {
      const id = nearestKnownId(event.target);
      if (!id) {
        return;
      }
      event.preventDefault();
      showAromaCategory(id);
    });
  } catch (_error) {
    wrap.innerHTML = "<p>Impossible de charger la roue des aromes.</p>";
  }
}

function bindTap(node, id) {
  if (node.dataset.bound === "1") {
    return;
  }
  node.dataset.bound = "1";

  const handler = (event) => {
    event.preventDefault();
    event.stopPropagation();
    showAromaCategory(id);
  };

  node.addEventListener("pointerdown", handler, { passive: false });
  node.addEventListener("touchstart", handler, { passive: false });
  node.addEventListener("click", handler, { passive: false });
}

function ensureHitArea(node) {
  if (!node) {
    return;
  }
  const tag = String(node.tagName || "").toLowerCase();
  if (!["path", "polygon", "circle", "ellipse"].includes(tag)) {
    return;
  }

  node.style.pointerEvents = "all";

  const fillAttr = String(node.getAttribute("fill") || "").trim().toLowerCase();
  const styleAttr = String(node.getAttribute("style") || "").toLowerCase();
  if (fillAttr === "none" || fillAttr === "" || styleAttr.includes("fill:none")) {
    node.style.fill = "rgba(0,0,0,0.001)";
  }

  const strokeOpacity = String(node.getAttribute("stroke-opacity") || "").trim();
  if (strokeOpacity === "0") {
    node.style.strokeOpacity = "0.001";
  }
}

function nearestKnownId(node) {
  let current = node;
  while (current) {
    if (current.id && knownShapeIds.has(current.id)) {
      return current.id;
    }
    current = current.parentElement;
  }
  return null;
}

function showAromaCategory(id) {
  const category = aromaCategories[id];
  if (!category) {
    return;
  }

  aromaTitleEl.textContent = category.title;
  aromaListEl.innerHTML = "";
  category.aromas.forEach((aroma) => {
    const item = document.createElement("li");
    item.textContent = aroma;
    aromaListEl.appendChild(item);
  });
}

function openGuide(type) {
  if (type === "visual") {
    guideTitleEl.textContent = "Visuel";
    guideContentEl.innerHTML = `
      <article class="guide-card">
        <h3>🍷 L'examen visuel du vin</h3>
        <p>L'examen visuel est la premiere etape de la degustation. Il renseigne sur l'age, le style et parfois l'etat du vin.</p>
      </article>
      <article class="guide-card">
        <h4>Intensite</h4>
        <ul>
          <li>Claire</li>
          <li>Moyenne</li>
          <li>Soutenue</li>
          <li>Foncee</li>
          <li>Profonde</li>
        </ul>
        <h4>Limpidite / Transparence</h4>
        <ul>
          <li>Cristalline</li>
          <li>Brillante</li>
          <li>Scintillante</li>
          <li>Voilee</li>
        </ul>
      </article>
      <article class="guide-card">
        <h4>Couleurs Blanc</h4>
        <p>Jaune pale, Jaune citron, Jaune paille, Or pale, Or, Vieil or, Ambre</p>
        <h4>Couleurs Rouge</h4>
        <p>Pourpre, Violet, Grenat, Cerise, Rubis, Tuile</p>
        <h4>Couleurs Rose</h4>
        <p>Pale, Petale de rose, Pelure d'oignon, Orange, Cuivre</p>
        <p class="guide-note">Astuce: compare les nuances entre elles, pas avec un nuancier.</p>
      </article>
    `;
    showView("guide");
    return;
  }

  if (type === "nose") {
    guideTitleEl.textContent = "Nez";
    guideContentEl.innerHTML = `
      <article class="guide-card">
        <h3>Aromes primaires</h3>
        <p>Issus directement du raisin: floral, fruits, vegetal, mineral percu.</p>
      </article>
      <article class="guide-card">
        <h3>Aromes secondaires</h3>
        <p>Nes pendant la fermentation et l'elevage sur lies: levure, brioche, beurre, biscuit...</p>
      </article>
      <article class="guide-card">
        <h3>Aromes tertiaires</h3>
        <p>Aromes d'evolution lies au vieillissement: epices, cacao, cafe, tabac, cuir, truffe, fruits secs...</p>
      </article>
      <article class="guide-card">
        <h3>Appreciation du nez</h3>
        <ul>
          <li>Style oxydatif: Oui / Non</li>
          <li>Finesse aromatique: Ordinaire / Fin / Elegant / Raffine</li>
          <li>Expression aromatique: Faible / Discret / Expressif / Intense</li>
        </ul>
      </article>
    `;
    showView("guide");
    return;
  }

  if (type === "gustative") {
    guideTitleEl.textContent = "Gustatif";
    guideContentEl.innerHTML = `
      <article class="guide-card">
        <h3>⚖️ Equilibre</h3>
        <p>Relation entre alcool, acidite, sucres et tanins.</p>
        <ul>
          <li>Desequilibre: trop acide, trop sucre, mou</li>
          <li>Vif ou structure: sec, corse, robuste</li>
          <li>Harmonieux: equilibre, veloute, souple</li>
        </ul>
      </article>
      <article class="guide-card">
        <h3>🧱 Structure</h3>
        <p>Matiere et densite du vin en bouche.</p>
        <ul>
          <li>Legere</li>
          <li>Moyenne</li>
          <li>Puissante</li>
        </ul>
      </article>
      <article class="guide-card">
        <h3>⏳ Persistance aromatique</h3>
        <p>Duree des aromes apres avoir avale ou recrache.</p>
        <ul>
          <li>Faible: 1-2 s</li>
          <li>Moyenne: 3-5 s</li>
          <li>Forte: 6-8 s</li>
          <li>Tres forte: 9 s et plus</li>
        </ul>
      </article>
      <article class="guide-card">
        <h3>🍷 Apogee</h3>
        <ul>
          <li>Trop jeune</li>
          <li>A son apogee</li>
          <li>En declin</li>
        </ul>
        <p class="guide-note">A retenir: l'equilibre, la puissance, la longueur et la maturite du vin.</p>
      </article>
    `;
    showView("guide");
  }
}

function resetEditor() {
  editingId = null;
  pendingImageData = null;
  form.reset();
  form.elements.rating.value = "4";
  ratingOutput.value = "4";
  photoPreview.classList.add("hidden");
  editorTitle.textContent = "Nouvelle fiche";
}

function loadCards() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      return [];
    }
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_error) {
    return [];
  }
}

function saveCards() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(cards));
}

function readFileAsDataURL(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(new Error("Lecture image impossible"));
    reader.readAsDataURL(file);
  });
}

function showToast(message) {
  toastEl.textContent = message;
  toastEl.classList.remove("hidden");
  window.clearTimeout(showToast.timerId);
  showToast.timerId = window.setTimeout(() => {
    toastEl.classList.add("hidden");
  }, 1500);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}
