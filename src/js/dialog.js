let dialog;
let dialogCallback;

function createDialog() {
    try {
        dialog = document.createElement("div");
        dialog.innerHTML = `
            <style>
                .translator-dialog-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, 0.5);
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    z-index: 99999;
                }
                .translator-dialog {
                    background: white;
                    border-radius: 8px;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
                    min-width: 400px;
                    max-width: 600px;
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                }
                .translator-dialog-header {
                    background: #0078d4;
                    color: white;
                    padding: 12px 16px;
                    font-size: 16px;
                    font-weight: 600;
                    border-radius: 8px 8px 0 0;
                }
                .translator-dialog-body {
                    padding: 16px;
                }
                .translator-field {
                    margin-bottom: 12px;
                }
                .translator-field label {
                    display: block;
                    font-size: 12px;
                    font-weight: 600;
                    color: #333;
                    margin-bottom: 4px;
                }
                .translator-captured-text {
                    background: #f5f5f5;
                    padding: 8px 12px;
                    border-radius: 4px;
                    font-size: 14px;
                    color: #333;
                    border: 1px solid #ddd;
                }
                .translator-page-info {
                    font-size: 13px;
                    color: #666;
                }
                .translator-input {
                    width: 100%;
                    padding: 8px 12px;
                    font-size: 14px;
                    border: 1px solid #ccc;
                    border-radius: 4px;
                    box-sizing: border-box;
                }
                .translator-input:focus {
                    outline: none;
                    border-color: #0078d4;
                    box-shadow: 0 0 0 2px rgba(0, 120, 212, 0.2);
                }
                .translator-tooltip-toggle {
                    margin-top: 12px;
                    display: none;
                }
                .translator-tooltip-toggle.visible {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    cursor: pointer;
                }
                .translator-tooltip-toggle input {
                    cursor: pointer;
                }
                .translator-tooltip-toggle label {
                    cursor: pointer;
                    font-size: 13px;
                    color: #0078d4;
                    user-select: none;
                }
                .translator-tooltip-section {
                    margin-top: 12px;
                    padding-top: 12px;
                    border-top: 1px solid #eee;
                    display: none;
                }
                .translator-tooltip-section.visible {
                    display: block;
                }
                .translator-tooltip-label {
                    color: #0078d4;
                    font-weight: 600;
                    font-size: 13px;
                    margin-bottom: 8px;
                }
                .translator-dialog-footer {
                    padding: 12px 16px;
                    display: flex;
                    justify-content: flex-end;
                    gap: 8px;
                    border-top: 1px solid #eee;
                }
                .translator-btn {
                    padding: 8px 16px;
                    font-size: 14px;
                    border-radius: 4px;
                    cursor: pointer;
                    border: none;
                }
                .translator-btn-ok {
                    background: #0078d4;
                    color: white;
                }
                .translator-btn-ok:hover {
                    background: #106ebe;
                }
                .translator-btn-cancel {
                    background: #f5f5f5;
                    color: #333;
                    border: 1px solid #ccc;
                }
                .translator-btn-cancel:hover {
                    background: #e5e5e5;
                }
            </style>
            <div class="translator-dialog">
                <div class="translator-dialog-header">Translation Capture</div>
                <div class="translator-dialog-body">
                    <div class="translator-field">
                        <label>Captured text:</label>
                        <div class="translator-captured-text" id="capturedText"></div>
                    </div>
                    <div class="translator-field">
                        <label>Page:</label>
                        <div class="translator-page-info" id="pageInfo"></div>
                    </div>
                    <div class="translator-field">
                        <label>Corrected translation:</label>
                        <input type="text" id="correctedTranslation" class="translator-input" />
                    </div>
                    <div class="translator-tooltip-toggle" id="tooltipToggle">
                        <input type="checkbox" id="editTooltipCheckbox" />
                        <label for="editTooltipCheckbox">Also edit ToolTip</label>
                    </div>
                    <div class="translator-tooltip-section" id="tooltipSection">
                        <div class="translator-field">
                            <label>Current tooltip:</label>
                            <div class="translator-captured-text" id="tooltipText"></div>
                        </div>
                        <div class="translator-field">
                            <label>Corrected tooltip:</label>
                            <input type="text" id="correctedTooltip" class="translator-input" placeholder="Leave empty to skip tooltip correction" />
                        </div>
                    </div>
                </div>
                <div class="translator-dialog-footer">
                    <button id="btnCancel" class="translator-btn translator-btn-cancel">Cancel</button>
                    <button id="btnOk" class="translator-btn translator-btn-ok">OK</button>
                </div>
            </div>
        `;
        dialog.className = "translator-dialog-overlay";

        dialog.style.display = "none";

        // Try to append to top document, fallback to current frame
        try {
            window.top.document.body.appendChild(dialog);
        } catch (e) {
            document.body.appendChild(dialog);
        }

        dialog.querySelector("#btnOk").addEventListener("click", () => {
            const corrected = dialog.querySelector("#correctedTranslation").value;
            const correctedTooltip = dialog.querySelector("#correctedTooltip").value;
            const callback = dialogCallback;
            hideDialog();
            if (callback) callback({ caption: corrected, tooltip: correctedTooltip });
        });

        dialog.querySelector("#btnCancel").addEventListener("click", () => {
            const callback = dialogCallback;
            hideDialog();
            if (callback) callback(null);
        });

        dialog.querySelector("#correctedTranslation").addEventListener("keyup", (e) => {
            if (e.key === "Enter") {
                dialog.querySelector("#btnOk").click();
            } else if (e.key === "Escape") {
                dialog.querySelector("#btnCancel").click();
            }
        });

        dialog.querySelector("#correctedTooltip").addEventListener("keyup", (e) => {
            if (e.key === "Enter") {
                dialog.querySelector("#btnOk").click();
            } else if (e.key === "Escape") {
                dialog.querySelector("#btnCancel").click();
            }
        });

        // Checkbox toggles tooltip section visibility
        dialog.querySelector("#editTooltipCheckbox").addEventListener("change", (e) => {
            const tooltipSection = dialog.querySelector("#tooltipSection");
            if (e.target.checked) {
                tooltipSection.classList.add("visible");
                dialog.querySelector("#correctedTooltip").focus();
            } else {
                tooltipSection.classList.remove("visible");
                dialog.querySelector("#correctedTooltip").value = "";
            }
        });
    } catch (err) {
        console.error("Failed to create dialog:", err);
    }
}

function showDialog(capturedText, pageTitle, pageId, tooltipText, elementType, callback) {
    if (!dialog) {
        // Fallback to simple prompt if dialog failed to create
        const result = prompt(`Captured: ${capturedText}\nPage: ${pageTitle} (ID: ${pageId})\n\nEnter corrected translation:`);
        callback({ caption: result, tooltip: null });
        return;
    }
    dialog.querySelector("#capturedText").textContent = capturedText;
    dialog.querySelector("#pageInfo").textContent = `${pageTitle} (ID: ${pageId || "Role Center"})`;
    dialog.querySelector("#correctedTranslation").value = "";
    dialog.querySelector("#correctedTooltip").value = "";

    const tooltipToggle = dialog.querySelector("#tooltipToggle");
    const tooltipSection = dialog.querySelector("#tooltipSection");
    const tooltipTextEl = dialog.querySelector("#tooltipText");
    const checkbox = dialog.querySelector("#editTooltipCheckbox");

    const hasTooltipText = tooltipText && tooltipText.trim();

    // Always show tooltip toggle
    tooltipToggle.classList.add("visible");

    // Set up the "Current tooltip" display
    if (hasTooltipText) {
        tooltipTextEl.textContent = tooltipText;
        tooltipTextEl.style.display = "block";
        tooltipTextEl.previousElementSibling.style.display = "block"; // label
    } else {
        tooltipTextEl.textContent = "(no tooltip captured)";
        tooltipTextEl.style.display = "block";
        tooltipTextEl.previousElementSibling.style.display = "block"; // label
    }

    // Tooltip section collapsed by default
    checkbox.checked = false;
    tooltipSection.classList.remove("visible");

    dialog.style.display = "flex";
    dialog.querySelector("#correctedTranslation").focus();
    dialogCallback = callback;
}

function hideDialog() {
    if (dialog) {
        dialog.style.display = "none";
    }
    dialogCallback = null;

    // Try to refocus the main content frame
    try {
        const frames = window.top.document.querySelectorAll("iframe");
        for (let frame of frames) {
            if (frame.contentDocument) {
                frame.contentWindow.focus();
                break;
            }
        }
    } catch (e) {
        // Ignore focus errors
    }
}
