namespace Forey.ALTranslation;

page 95001 TranslationList
{
    Caption = 'Translations';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = TranslationDB;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Translated Text"; Rec."Translated Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'The original text captured from the UI';
                }
                field("Area of text"; Rec."Area of text")
                {
                    ApplicationArea = All;
                    ToolTip = 'The page or area where the text was captured';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The Business Central page ID';
                }
                field("Corrected Translation"; Rec."Corrected Translation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Your corrected translation for this text';
                }
                field("Element Type"; Rec."Element Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Type of UI element: Field, Action, Menu, Tab, Column';
                }
                field("Property Type"; Rec."Property Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Caption or ToolTip';
                }
                field("UI Area"; Rec."UI Area")
                {
                    ApplicationArea = All;
                    ToolTip = 'Ribbon, List, Dialog, Content';
                }
                field(Synced; Rec.Synced)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Indicates if this record has been synced to Cosmos DB';
                    StyleExpr = SyncedStyle;
                }
                field("Synced DateTime"; Rec."Synced DateTime")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'When this record was synced to Cosmos DB';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = All;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncSelected)
            {
                Caption = 'Sync Selected';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Sync the selected records to Cosmos DB';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TranslationDB: Record TranslationDB;
                    TranslationSync: Codeunit TranslationSync;
                    SyncCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(TranslationDB);
                    if TranslationDB.FindSet() then
                        repeat
                            if not TranslationDB.Synced then
                                if TranslationSync.SyncSingleRecord(TranslationDB) then
                                    SyncCount += 1;
                        until TranslationDB.Next() = 0;

                    Message('%1 record(s) synced.', SyncCount);
                    CurrPage.Update(false);
                end;
            }
            action(MarkAsUnsynced)
            {
                Caption = 'Mark as Unsynced';
                ApplicationArea = All;
                Image = Undo;
                ToolTip = 'Mark the selected records as unsynced (will be re-synced on next run)';

                trigger OnAction()
                var
                    TranslationDB: Record TranslationDB;
                begin
                    CurrPage.SetSelectionFilter(TranslationDB);
                    TranslationDB.ModifyAll(Synced, false);
                    TranslationDB.ModifyAll("Synced DateTime", 0DT);
                    CurrPage.Update(false);
                    Message('Selected records marked as unsynced.');
                end;
            }
            action(OpenSetup)
            {
                Caption = 'Setup';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Open the Translation Setup page';
                RunObject = page TranslationSetup;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Synced then
            SyncedStyle := 'Favorable'
        else
            SyncedStyle := 'Ambiguous';
    end;

    var
        SyncedStyle: Text;
}
