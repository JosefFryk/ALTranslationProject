namespace Forey.ALTranslation;

page 95006 TranslationsListPart
{
    Caption = 'Translations';
    PageType = ListPart;
    SourceTable = TranslationDB;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Translated Text"; Rec."Translated Text")
                {
                    ApplicationArea = All;
                }
                field("Corrected Translation"; Rec."Corrected Translation")
                {
                    ApplicationArea = All;
                }
                field(Synced; Rec.Synced)
                {
                    ApplicationArea = All;
                    StyleExpr = SyncedStyle;
                }
                field("Element Type"; Rec."Element Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncAll)
            {
                Caption = 'Sync All';
                ApplicationArea = All;
                Image = RefreshLines;
                ToolTip = 'Sync all pending records to Cosmos DB';

                trigger OnAction()
                var
                    TranslationSync: Codeunit TranslationSync;
                begin
                    if TranslationSync.RunSyncManual() then
                        Message('Sync completed successfully.')
                    else
                        Message('Sync completed with errors.');
                    CurrPage.Update(false);
                end;
            }
            action(SyncSelected)
            {
                Caption = 'Sync Selected';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Sync selected records to Cosmos DB';

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
            action(OpenList)
            {
                Caption = 'Open Full List';
                ApplicationArea = All;
                Image = List;
                ToolTip = 'Open the full Translations list';

                trigger OnAction()
                begin
                    Page.Run(Page::TranslationList);
                end;
            }
            action(Setup)
            {
                Caption = 'Setup';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Open Translation Setup';

                trigger OnAction()
                begin
                    Page.Run(Page::TranslationSetup);
                end;
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
