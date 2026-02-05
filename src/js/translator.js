function getALMethod(name, SKIP_IF_BUSY) {
    const nav = Microsoft.Dynamics.NAV.GetEnvironment();

    return (...args) => {
        let result;

        window["OnInvokeResult"] = function (alResult) {
            result = alResult;
        }

        return new Promise(resolve => {
            if (SKIP_IF_BUSY && nav.Busy) {
                resolve(SKIP_IF_BUSY);
                return;
            }

            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args, false, () => {
                delete window.OnInvokeResult;
                resolve(result);
            });
        });
    }
}

let indicator;
let isListening = false;
let frameListeners = []; // Track listeners for removal

// Parsed shortcut configuration
let shortcutConfig = {
    ctrl: true,
    shift: true,
    alt: false,
    key: 'f'
};

// Parse shortcut string like "Ctrl+Shift+F" or "Alt+T"
function parseShortcut(shortcut) {
    const config = {
        ctrl: false,
        shift: false,
        alt: false,
        key: ''
    };

    if (!shortcut) return config;

    const parts = shortcut.toLowerCase().split('+').map(p => p.trim());

    for (const part of parts) {
        if (part === 'ctrl' || part === 'control') {
            config.ctrl = true;
        } else if (part === 'shift') {
            config.shift = true;
        } else if (part === 'alt') {
            config.alt = true;
        } else if (part.length === 1) {
            // Single character key
            config.key = part;
        } else {
            // Could be special key like "enter", "space", etc.
            config.key = part;
        }
    }

    return config;
}

// Start listening with a custom shortcut
function startListeningWithShortcut(shortcut) {
    shortcutConfig = parseShortcut(shortcut);
    startListeningInFrames();
}

function initialize() {
    indicator = document.createElement("div");
    indicator.className = "indicator";
    document.getElementById("controlAddIn").append(indicator);

    // Click handler for toggle (handled in JS, no AL callback needed)
    indicator.addEventListener("click", () => {
        if (isListening) {
            stopListening();
        } else {
            startListeningInFrames();
        }
    });

    createDialog();
}

function stopListening() {
    // Remove all registered event listeners
    for (const item of frameListeners) {
        item.doc.removeEventListener("mousemove", item.mousemoveHandler, true);
        item.doc.removeEventListener("keyup", item.keyupHandler, true);
    }
    frameListeners = [];
    isListening = false;
    indicator.className = "indicator off";
    indicator.innerText = "";
}

function hideIndicator() {
    indicator.style.display = "none";
}

function Update() {
    indicator.className = "indicator updated";
}

// function StartListening() {
//     indicator.className = "indicator on";

//     // const keyPressed = getALMethod("OnKeyPressed");
//     // const frames = window.top.document.querySelectorAll("iframe");
//     // for (let frame of frames) {
//     //     frame.contentDocument.addEventListener("keyup", e => {
//     //         const data = { key: e.key, shift: e.shiftKey, ctrl: e.ctrlKey, alt: e.altKey };
//     //         indicator.className = "indicator on";
//     //         indicator.innerText = e.key;
//     //         keyPressed(data);
//     //     });
//     // }
// }

function startListeningInFrames() {
    // Clear any existing listeners first
    stopListening();

    isListening = true;
    indicator.className = "indicator on";

    const captured = getALMethod("OnCaptured");

    const frames = window.top.document.querySelectorAll("iframe");

    for (let frame of frames) {
        const doc = frame.contentDocument;
        if (!doc) continue;

        let lastX = 0;
        let lastY = 0;

        const mousemoveHandler = (e) => {
            lastX = e.clientX;
            lastY = e.clientY;
        };

        const keyupHandler = (e) => {
            if (!isListening) return;

            // Check if the configured shortcut was pressed
            const keyPressed = (e.key || "").toLowerCase();
            const shortcutMatch =
                e.ctrlKey === shortcutConfig.ctrl &&
                e.shiftKey === shortcutConfig.shift &&
                e.altKey === shortcutConfig.alt &&
                keyPressed === shortcutConfig.key;

            if (shortcutMatch) {
                const el = doc.elementFromPoint(lastX, lastY);
                if (!el) return;

                // Collect all element context
                const elementContext = collectElementContext(el, frameIndex);

                const rawTitle = (window.top?.document?.title || doc.title || "").trim();
                const pageTitle = normalizePageTitle(rawTitle);
                const pageId = getPageIdFromUrl();

                // Pass tooltip text (title attribute) and element type to dialog
                const tooltipText = elementContext.title || "";
                const elementType = elementContext.elementType || "";

                showDialog(elementContext.text, pageTitle, pageId, tooltipText, elementType, (result) => {
                    // User cancelled
                    if (result === null) return;

                    const { caption, tooltip } = result;

                    // Create caption record if caption correction provided
                    if (caption && caption.trim()) {
                        const captionPayload = {
                            // Basic fields
                            text: elementContext.text,
                            area: pageTitle,
                            pageId: pageId,
                            correctedTranslation: caption,
                            // Element identification
                            elementType: elementContext.elementType,
                            propertyType: "Caption",
                            uiArea: elementContext.uiArea,
                            // HTML attributes
                            tag: elementContext.tag,
                            role: elementContext.role,
                            aria: elementContext.ariaLabel,
                            title: elementContext.title,
                            elementId: elementContext.elementId,
                            elementName: elementContext.elementName,
                            cssClasses: elementContext.cssClasses,
                            placeholder: elementContext.placeholder,
                            // Extended context
                            innerText: elementContext.innerText,
                            parentChain: elementContext.parentChain,
                            dataAttributes: elementContext.dataAttributes,
                            selectorPath: elementContext.selectorPath,
                            isToolTip: false,
                            frameIndex: elementContext.frameIndex,
                            // BC metadata for XLIFF matching
                            sourceTableId: elementContext.sourceTableId,
                            tableFieldNo: elementContext.tableFieldNo,
                            bcFieldName: elementContext.bcFieldName,
                            bcDesignName: elementContext.bcDesignName
                        };

                        captured(captionPayload);
                    }

                    // Create tooltip record if tooltip correction provided
                    // User can provide tooltip correction even without captured tooltip text
                    if (tooltip && tooltip.trim()) {
                        const tooltipPayload = {
                            // Basic fields - use tooltip text as source if available, otherwise use caption text
                            text: tooltipText.trim() || elementContext.text,
                            area: pageTitle,
                            pageId: pageId,
                            correctedTranslation: tooltip,
                            // Element identification
                            elementType: elementContext.elementType,
                            propertyType: "ToolTip",
                            uiArea: elementContext.uiArea,
                            // HTML attributes
                            tag: elementContext.tag,
                            role: elementContext.role,
                            aria: elementContext.ariaLabel,
                            title: elementContext.title,
                            elementId: elementContext.elementId,
                            elementName: elementContext.elementName,
                            cssClasses: elementContext.cssClasses,
                            placeholder: elementContext.placeholder,
                            // Extended context
                            innerText: elementContext.innerText,
                            parentChain: elementContext.parentChain,
                            dataAttributes: elementContext.dataAttributes,
                            selectorPath: elementContext.selectorPath,
                            isToolTip: true,
                            frameIndex: elementContext.frameIndex,
                            // BC metadata for XLIFF matching
                            sourceTableId: elementContext.sourceTableId,
                            tableFieldNo: elementContext.tableFieldNo,
                            bcFieldName: elementContext.bcFieldName,
                            bcDesignName: elementContext.bcDesignName
                        };

                        captured(tooltipPayload);
                    }
                });
            }
        };

        // Track frame index for this iframe
        const frameIndex = Array.from(frames).indexOf(frame);

        doc.addEventListener("mousemove", mousemoveHandler, true);
        doc.addEventListener("keyup", keyupHandler, true);

        // Store references for later removal
        frameListeners.push({
            doc: doc,
            mousemoveHandler: mousemoveHandler,
            keyupHandler: keyupHandler
        });
    }
}

function getElementTextUnderCursor(doc, x, y) {
    const el = doc.elementFromPoint(x, y);
    if (!el) return null;

    const aria = el.getAttribute?.("aria-label") || "";
    const title = el.getAttribute?.("title") || "";
    const text =
        (aria && aria.trim()) ||
        (el.innerText && el.innerText.trim()) ||
        (el.textContent && el.textContent.trim()) ||
        (title && title.trim()) ||
        "";

    return {
        text,
        aria,
        title,
        tag: el.tagName,
        className: el.className || "",
        role: el.getAttribute?.("role") || ""
    };
}
// --- helper: show message (for now) ---
function showCapturedMessage(frameIndex, data, areaOfText) {
    if (!data || !data.text) {
        alert(`[${frameIndex}] No text under cursor.`);
        return;
    }

    alert(
        `[${frameIndex}] Captured:\n\n` +
        `Text: ${data.text}\n` +
        `Area: ${areaOfText}\n` +
        (data.aria ? `Aria: ${data.aria}\n` : "") +
        (data.role ? `Role: ${data.role}\n` : "") +
        (data.title ? `Title: ${data.title}\n` : "") +
        `Tag: ${data.tag}`
    );
}

// --- helpers for classification (AL/XLIFF terminology) ---
function detectUIType(el) {
    const role = el.getAttribute?.("role") || "";
    const tag = (el.tagName || "").toLowerCase();
    const cls = (el.className || "").toString().toLowerCase();

    // Check parent context for better classification
    const parentContext = getParentContext(el);

    // BC-specific: Field detection by CSS class (highest priority)
    // ms-nav-edit-control-caption = field label
    // ms-nav-edit-control = field container
    if (cls.includes("ms-nav-edit-control") || cls.includes("edit-control-caption")) {
        return "Field";
    }

    // Check parent classes for field context
    if (parentContext.inFieldControl) {
        return "Field";
    }

    // BC-specific: Action bar buttons
    if (cls.includes("ms-nav-action") || cls.includes("command-button")) {
        return "Action";
    }

    // Grid cells - columns in a list
    // Check element itself
    if (role === "gridcell" || role === "columnheader" || cls.includes("ms-nav-grid")) {
        return "Column";
    }
    // Check parent elements for column header context (BC puts role="columnheader" on TH parent)
    if (parentContext.inGrid) {
        let parent = el.parentElement;
        let depth = 0;
        while (parent && depth < 5) {
            const parentRole = parent.getAttribute?.("role") || "";
            const parentCls = (parent.className || "").toString().toLowerCase();
            if (parentRole === "columnheader" || parentCls.includes("columncaption")) {
                return "Column";
            }
            parent = parent.parentElement;
            depth++;
        }
    }

    // Tabs
    if (role === "tab" || parentContext.inTabList || cls.includes("ms-nav-band-header")) {
        return "Tab";
    }

    // Actions - buttons ONLY in action bar/ribbon area
    if (role === "button" || role === "menuitem") {
        // If in action bar or command bar -> Action
        if (parentContext.inActionBar || parentContext.inCommandBar || parentContext.inMenu) {
            return "Action";
        }
        // If in field group or content area -> it's a field drilldown/lookup button
        if (parentContext.inFieldGroup || parentContext.inFieldControl) {
            return "Field";
        }
    }

    // Menu items are always Actions
    if (role === "menuitem" || parentContext.inMenu) {
        return "Action";
    }

    // Fields - input elements
    if (role === "textbox" || role === "combobox" || role === "spinbutton" ||
        tag === "input" || tag === "textarea" || tag === "select") {
        return "Field";
    }

    // Labels
    if (tag === "label" || role === "label") {
        return "Field";
    }

    // Check by parent context
    if (parentContext.inFieldGroup) {
        return "Field";
    }

    if (parentContext.inFactBox) {
        return "Control";
    }

    if (parentContext.inActionBar || parentContext.inCommandBar) {
        return "Action";
    }

    // Cue tiles
    if (cls.includes("cue") || parentContext.inCueGroup) {
        return "Cue";
    }

    return "Control";
}

function detectUIArea(el) {
    const parentContext = getParentContext(el);

    if (parentContext.inCommandBar || parentContext.inActionBar) return "ActionBar";
    if (parentContext.inMenu) return "Menu";
    if (parentContext.inDialog) return "Dialog";
    if (parentContext.inFactBox) return "FactBox";
    if (parentContext.inGrid) return "List";
    if (parentContext.inCueGroup) return "CueGroup";
    if (parentContext.inTabList) return "Tabs";
    if (parentContext.inFieldGroup) return "Group";
    if (parentContext.inContentArea) return "ContentArea";

    return "Page";
}

// Walk up the DOM tree to understand context
function getParentContext(el) {
    const context = {
        inActionBar: false,
        inCommandBar: false,
        inMenu: false,
        inDialog: false,
        inFactBox: false,
        inGrid: false,
        inFieldGroup: false,
        inFieldControl: false,  // BC-specific: ms-nav-edit-control
        inContentArea: false,
        inCueGroup: false,
        inTabList: false,
        parentRoles: [],
        parentClasses: []
    };

    let cur = el;
    let depth = 0;

    while (cur && depth < 15) {
        const role = cur.getAttribute?.("role") || "";
        const cls = (cur.className || "").toString().toLowerCase();
        const tag = (cur.tagName || "").toLowerCase();

        // Collect for debugging
        if (role) context.parentRoles.push(role);
        if (cls) context.parentClasses.push(cls.substring(0, 50));

        // Action bar / Command bar detection
        if (cls.includes("command-bar") || cls.includes("commandbar") ||
            cls.includes("action-bar") || cls.includes("actionbar") ||
            cls.includes("ms-commandbar") || role === "toolbar" ||
            cls.includes("ribbon")) {
            context.inActionBar = true;
            context.inCommandBar = true;
        }

        // Menu detection - be specific to avoid matching "contextmenu-trigger" or similar
        const isActualMenu = role === "menu" || role === "menubar" ||
            (cls.includes("menu") && !cls.includes("contextmenu") && !cls.includes("-menu-trigger")) ||
            cls.includes("dropdown") || cls.includes("popup");
        if (isActualMenu) {
            context.inMenu = true;
        }

        // Dialog detection
        if (role === "dialog" || role === "alertdialog" || cls.includes("dialog") ||
            cls.includes("modal")) {
            context.inDialog = true;
        }

        // FactBox detection
        if (cls.includes("factbox") || cls.includes("fact-box")) {
            context.inFactBox = true;
        }

        // Grid/List detection
        if (role === "grid" || role === "table" || role === "treegrid" ||
            cls.includes("grid") || cls.includes("list-view")) {
            context.inGrid = true;
        }

        // Field group detection (BC uses groups for organizing fields)
        if (cls.includes("field-group") || cls.includes("fieldgroup") ||
            cls.includes("group") || cls.includes("fast-tab") ||
            cls.includes("fasttab") || role === "group") {
            context.inFieldGroup = true;
        }

        // BC-specific: Field control detection
        if (cls.includes("ms-nav-edit-control") || cls.includes("edit-control")) {
            context.inFieldControl = true;
        }

        // Content area detection
        if (cls.includes("content-area") || cls.includes("contentarea") ||
            cls.includes("page-content") || cls.includes("card-body") ||
            cls.includes("form-content") || role === "main" ||
            cls.includes("scroll-content")) {
            context.inContentArea = true;
        }

        // Cue group detection
        if (cls.includes("cue") || cls.includes("tile")) {
            context.inCueGroup = true;
        }

        // Tab list detection
        if (role === "tablist" || cls.includes("tab-list") || cls.includes("tablist") ||
            cls.includes("pivot")) {
            context.inTabList = true;
        }

        cur = cur.parentElement;
        depth++;
    }

    return context;
}

function normalizePageTitle(title) {
    // Simplify page title to just the Czech page name
    // Examples:
    //   "Karta zboží | Pracovní datum: 28.01.2027 - 1120 ∙ Špice" → "Karta zboží"
    //   "E-shop - přehled nastavení (PROD)" → "E-shop - přehled nastavení"
    //   "Účetní osnova - Dynamics 365 Business Central" → "Účetní osnova"

    let result = (title || "").trim();

    // Remove "- Dynamics 365 Business Central" suffix
    result = result.replace(/\s*-\s*Dynamics 365 Business Central.*$/i, "");

    // Remove everything after " | " (working date and record info)
    const pipeIndex = result.indexOf(" | ");
    if (pipeIndex > 0) {
        result = result.substring(0, pipeIndex);
    }

    // Remove trailing environment markers like "(PROD)", "(MIG)", "(TEST)"
    result = result.replace(/\s*\((PROD|MIG|TEST|DEV)\)\s*$/i, "");

    // Remove record identifier pattern at end: " - NUMBER ∙ NAME" or " ∙ NAME"
    result = result.replace(/\s*-\s*[\w\d-]+\s*∙.*$/i, "");
    result = result.replace(/\s*∙.*$/i, "");

    return result.trim();
}

function getPageIdFromUrl() {
    try {
        const url = new URL(window.top.location.href);
        return url.searchParams.get("page") || "";
    } catch (e) {
        return "";
    }
}

function safeTruncate(s, maxLen) {
    s = (s || "").toString();
    return s.length <= maxLen ? s : s.substring(0, maxLen);
}

// Extract BC metadata from the DOM element's internal adapter
// This provides sourceTableId, tableFieldNo, and field name for XLIFF matching
function extractBCMetadata(el) {
    const metadata = {
        sourceTableId: null,
        tableFieldNo: null,
        fieldName: null,
        designName: null,
        controlId: null,
        sourceAppId: null
    };

    try {
        // Walk up to find the control container with _adapter
        let current = el;
        let depth = 0;
        while (current && depth < 10) {
            if (current._adapter && current._adapter.$logicalControl) {
                const lc = current._adapter.$logicalControl;

                // Get field-level info
                metadata.tableFieldNo = lc.tableFieldNo !== undefined && lc.tableFieldNo !== -1
                    ? lc.tableFieldNo : null;
                metadata.fieldName = lc.name || null;
                metadata.designName = lc.designName || null;
                metadata.controlId = current.id || null;
                metadata.sourceAppId = lc.sourceAppId || null;

                // Get form-level info (sourceTableId) from the context
                // Try multiple paths as context structure can vary
                let sourceTableId = null;

                // Path 1: Walk up the _parent chain to find form with metadata
                let parentControl = lc._parent;
                let parentDepth = 0;
                while (parentControl && parentDepth < 30 && !sourceTableId) {
                    if (parentControl.metadata && parentControl.metadata.sourceTableId !== undefined) {
                        sourceTableId = parentControl.metadata.sourceTableId;
                        break;
                    }
                    parentControl = parentControl._parent;
                    parentDepth++;
                }

                // Path 2: Try through context.session._formManager
                // Important: Filter to find the form matching the current page ID
                if (!sourceTableId) {
                    const currentPageId = getPageIdFromUrl();

                    if (lc._context && lc._context.session && lc._context.session._formManager) {
                        const fm = lc._context.session._formManager;
                        if (fm._openedRootForms) {
                            // Find form matching current page ID
                            for (const key of Object.keys(fm._openedRootForms)) {
                                const form = fm._openedRootForms[key];
                                if (form && form.metadata) {
                                    const formPageId = form.metadata.id || (form.cacheKey ? parseInt(form.cacheKey.split(':')[0]) : null);

                                    // Match by page ID
                                    if (currentPageId && formPageId && String(formPageId) === String(currentPageId)) {
                                        if (form.metadata.sourceTableId !== undefined) {
                                            sourceTableId = form.metadata.sourceTableId;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Path 3: Try to find through DOM - look for form element with _adapter
                if (!sourceTableId) {
                    const doc = current.ownerDocument;
                    if (doc) {
                        const formEl = doc.querySelector('form[aria-label], .ms-nav-cardform, .ms-nav-listform');
                        if (formEl && formEl._adapter && formEl._adapter.$logicalControl) {
                            const formLc = formEl._adapter.$logicalControl;
                            if (formLc.metadata && formLc.metadata.sourceTableId !== undefined) {
                                sourceTableId = formLc.metadata.sourceTableId;
                            }
                        }
                    }
                }

                // Path 4: Walk up DOM elements to find one with form metadata
                if (!sourceTableId) {
                    let domParent = current.parentElement;
                    let domDepth = 0;
                    while (domParent && domDepth < 30 && !sourceTableId) {
                        if (domParent._adapter && domParent._adapter.$logicalControl) {
                            const parentLc = domParent._adapter.$logicalControl;
                            if (parentLc.metadata && parentLc.metadata.sourceTableId !== undefined) {
                                sourceTableId = parentLc.metadata.sourceTableId;
                                break;
                            }
                        }
                        domParent = domParent.parentElement;
                        domDepth++;
                    }
                }

                metadata.sourceTableId = sourceTableId;
                break;
            }
            current = current.parentElement;
            depth++;
        }
    } catch (e) {
        // Silently fail - metadata extraction is optional
        console.warn('BC metadata extraction failed:', e);
    }

    return metadata;
}

// Collect comprehensive element context for XLIFF matching
function collectElementContext(el, frameIndex) {
    const ariaLabel = el.getAttribute?.("aria-label") || "";
    const title = el.getAttribute?.("title") || "";
    const role = el.getAttribute?.("role") || "";
    const innerText = (el.innerText || "").trim();
    const textContent = (el.textContent || "").trim();
    const placeholder = el.getAttribute?.("placeholder") || "";

    // Determine if this is a tooltip capture
    const isToolTip = title !== "" && (title === innerText || !innerText);

    // Determine the captured text (priority order)
    let text =
        (ariaLabel && ariaLabel.trim()) ||
        (innerText) ||
        (textContent) ||
        (title && title.trim()) ||
        "";

    // Strip BC sorting suffixes (e.g., ", seřazeno v Vzestupně pořadí")
    const commaIndex = text.indexOf(',');
    if (commaIndex > 0) {
        text = text.substring(0, commaIndex).trim();
    }

    // Determine property type
    const propertyType = isToolTip ? "ToolTip" : "Caption";

    // Get parent context for classification
    const parentContext = getParentContext(el);

    // Get element type using context-aware function
    const elementType = detectUIType(el);

    // Get UI area using context-aware function
    const uiArea = detectUIArea(el);

    // Collect all data-* attributes
    const dataAttributes = {};
    if (el.dataset) {
        for (const key in el.dataset) {
            dataAttributes[key] = el.dataset[key];
        }
    }

    // Build parent chain (up to 10 levels) - include all for debugging
    const parentChain = [];
    let current = el.parentElement;
    let depth = 0;
    while (current && depth < 10) {
        const parentInfo = {
            tag: current.tagName,
            role: current.getAttribute?.("role") || "",
            id: current.id || "",
            classes: (current.className || "").toString().substring(0, 100),
            ariaLabel: (current.getAttribute?.("aria-label") || "").substring(0, 50)
        };
        // Include all parents for debugging purposes
        parentChain.push(parentInfo);
        current = current.parentElement;
        depth++;
    }

    // Add context flags for debugging
    const contextFlags = {
        inActionBar: parentContext.inActionBar,
        inCommandBar: parentContext.inCommandBar,
        inMenu: parentContext.inMenu,
        inDialog: parentContext.inDialog,
        inFactBox: parentContext.inFactBox,
        inGrid: parentContext.inGrid,
        inFieldGroup: parentContext.inFieldGroup,
        inFieldControl: parentContext.inFieldControl,
        inContentArea: parentContext.inContentArea,
        inCueGroup: parentContext.inCueGroup,
        inTabList: parentContext.inTabList
    };

    // Build CSS selector path
    const selectorPath = buildSelectorPath(el);

    // Extract BC metadata (sourceTableId, tableFieldNo, fieldName)
    const bcMetadata = extractBCMetadata(el);

    return {
        text: text,
        elementType: elementType,
        propertyType: propertyType,
        uiArea: uiArea,
        tag: el.tagName || "",
        role: role,
        ariaLabel: ariaLabel,
        title: title,
        elementId: el.id || "",
        elementName: el.name || el.getAttribute?.("name") || "",
        cssClasses: (el.className || "").toString(),
        placeholder: placeholder,
        innerText: safeTruncate(innerText, 500),
        parentChain: JSON.stringify(parentChain),
        dataAttributes: JSON.stringify({ ...dataAttributes, _contextFlags: contextFlags }),
        selectorPath: selectorPath,
        isToolTip: isToolTip,
        frameIndex: frameIndex,
        // BC metadata for XLIFF matching
        sourceTableId: bcMetadata.sourceTableId,
        tableFieldNo: bcMetadata.tableFieldNo,
        bcFieldName: bcMetadata.fieldName,
        bcDesignName: bcMetadata.designName,
        bcControlId: bcMetadata.controlId,
        bcSourceAppId: bcMetadata.sourceAppId
    };
}

// Build a CSS selector path to identify the element
function buildSelectorPath(el) {
    const parts = [];
    let current = el;
    let depth = 0;

    while (current && current.tagName && depth < 8) {
        let selector = current.tagName.toLowerCase();

        if (current.id) {
            selector += "#" + current.id;
        } else {
            const role = current.getAttribute?.("role");
            if (role) {
                selector += "[role=" + role + "]";
            }

            // Add index if there are siblings with same tag
            const parent = current.parentElement;
            if (parent) {
                const siblings = parent.querySelectorAll(":scope > " + current.tagName.toLowerCase());
                if (siblings.length > 1) {
                    const index = Array.from(siblings).indexOf(current);
                    selector += ":nth-of-type(" + (index + 1) + ")";
                }
            }
        }

        parts.unshift(selector);
        current = current.parentElement;
        depth++;
    }

    return parts.join(" > ");
}
