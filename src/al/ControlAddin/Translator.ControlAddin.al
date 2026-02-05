namespace Forey.ALTranslation;

controladdin Translator
{
    RequestedHeight = 100;
    RequestedWidth = 100;
    VerticalStretch = false;
    HorizontalStretch = false;

    Scripts = 'src\js\translator.js', 'src\js\dialog.js';
    StyleSheets = 'src\css\TranslatorButton.css', 'src\css\dialog.css';
    StartupScript = 'src\js\start.js';


    event OnControlReady();
    event OnCaptured(Data: JsonObject);

    procedure startListeningInFrames();
    procedure startListeningWithShortcut(shortcut: Text);
    procedure stopListening();
    procedure hideIndicator();
    procedure Update();
}