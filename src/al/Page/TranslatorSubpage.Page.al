namespace Forey.ALTranslation;
using System.Reflection;

page 95000 TranslatorSubpage
{
    PageType = CardPart;
    Caption = ' ';

    layout
    {
        area(Content)
        {
            usercontrol(Translator; Translator)
            {
                ApplicationArea = All;

                trigger OnControlReady()
                var
                    TranslatorCU: Codeunit Translator;
                    TranslationSetup: Record TranslationSetup;
                    Shortcut: Text;
                begin
                    if TranslationSetup.GetSetup() and (TranslationSetup."Capture Shortcut" <> '') then
                        Shortcut := TranslationSetup."Capture Shortcut"
                    else
                        Shortcut := 'Ctrl+Shift+F';

                    CurrPage.Translator.startListeningWithShortcut(Shortcut);
                    TranslatorCU.Initialize(CurrPage.Translator);
                end;

                trigger OnCaptured(Data: JsonObject)
                var
                    DB: Record TranslationDB;
                    Tok: JsonToken;
                    TranslatedText: Text;
                    AreaOfText: Text;
                    PageIdText: Text;
                    CorrectedTranslation: Text;
                    PageId: Integer;
                    FrameIdx: Integer;
                begin
                    if Data.Get('text', Tok) then
                        TranslatedText := Tok.AsValue().AsText();

                    if Data.Get('area', Tok) then
                        AreaOfText := Tok.AsValue().AsText();

                    if Data.Get('pageId', Tok) then
                        PageIdText := Tok.AsValue().AsText();

                    if Data.Get('correctedTranslation', Tok) then
                        CorrectedTranslation := Tok.AsValue().AsText();

                    if TranslatedText = '' then
                        exit;

                    if PageIdText <> '' then
                        Evaluate(PageId, PageIdText, 9)
                    else begin
                        PageId := 0;
                        AreaOfText := 'Role Center';
                    end;

                    DB.Init();
                    // Basic fields
                    DB."Translated Text" := CopyStr(TranslatedText, 1, MaxStrLen(DB."Translated Text"));
                    DB."Area of text" := CopyStr(AreaOfText, 1, MaxStrLen(DB."Area of text"));
                    DB."Page ID" := PageId;
                    DB."Page Name" := GetPageName(PageId);
                    DB."Corrected Translation" := CopyStr(CorrectedTranslation, 1, MaxStrLen(DB."Corrected Translation"));

                    // Element identification fields
                    if Data.Get('elementType', Tok) then
                        DB."Element Type" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Element Type"));

                    if Data.Get('propertyType', Tok) then
                        DB."Property Type" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Property Type"));

                    if Data.Get('uiArea', Tok) then
                        DB."UI Area" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."UI Area"));

                    if Data.Get('tag', Tok) then
                        DB."HTML Tag" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."HTML Tag"));

                    if Data.Get('role', Tok) then
                        DB."ARIA Role" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."ARIA Role"));

                    if Data.Get('aria', Tok) then
                        DB."ARIA Label" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."ARIA Label"));

                    if Data.Get('title', Tok) then
                        DB."Title Attribute" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Title Attribute"));

                    if Data.Get('elementId', Tok) then
                        DB."Element ID" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Element ID"));

                    if Data.Get('elementName', Tok) then
                        DB."Element Name" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Element Name"));

                    if Data.Get('cssClasses', Tok) then
                        DB."CSS Classes" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."CSS Classes"));

                    if Data.Get('parentChain', Tok) then
                        DB."Parent Chain" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Parent Chain"));

                    if Data.Get('dataAttributes', Tok) then
                        DB."Data Attributes" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Data Attributes"));

                    if Data.Get('selectorPath', Tok) then
                        DB."Selector Path" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Selector Path"));

                    if Data.Get('innerText', Tok) then
                        DB."Inner Text" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."Inner Text"));

                    if Data.Get('placeholder', Tok) then
                        DB.Placeholder := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB.Placeholder));

                    if Data.Get('isToolTip', Tok) then
                        DB."Is ToolTip" := Tok.AsValue().AsBoolean();

                    if Data.Get('frameIndex', Tok) then begin
                        FrameIdx := Tok.AsValue().AsInteger();
                        DB."Frame Index" := FrameIdx;
                    end;

                    // BC metadata fields for XLIFF matching
                    if Data.Get('sourceTableId', Tok) then
                        if not Tok.AsValue().IsNull() then
                            DB."Source Table ID" := Tok.AsValue().AsInteger();

                    if Data.Get('tableFieldNo', Tok) then
                        if not Tok.AsValue().IsNull() then
                            DB."Table Field No." := Tok.AsValue().AsInteger();

                    if Data.Get('bcFieldName', Tok) then
                        if not Tok.AsValue().IsNull() then
                            DB."BC Field Name" := CopyStr(Tok.AsValue().AsText(), 1, MaxStrLen(DB."BC Field Name"));

                    // Look up table name from Table Metadata if we have sourceTableId
                    if DB."Source Table ID" <> 0 then
                        DB."Table Name" := GetTableName(DB."Source Table ID");

                    DB.Insert(true);
                end;
            }
        }
    }

    local procedure GetPageName(PageId: Integer): Text[100]
    var
        PageMetadata: Record "Page Metadata";
    begin
        if PageId = 0 then
            exit('');
        if PageMetadata.Get(PageId) then
            exit(CopyStr(PageMetadata.Name, 1, 100));
        exit('');
    end;

    local procedure GetTableName(TableId: Integer): Text[100]
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableId = 0 then
            exit('');
        if TableMetadata.Get(TableId) then
            exit(CopyStr(TableMetadata.Name, 1, 100));
        exit('');
    end;
}
