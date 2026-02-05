namespace Forey.ALTranslation;

page 95002 TranslationSetup
{
    Caption = 'Translation Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = TranslationSetup;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(CosmosDB)
            {
                Caption = 'Azure Cosmos DB';

                field("Cosmos DB Endpoint"; Rec."Cosmos DB Endpoint")
                {
                    ApplicationArea = All;
                    ToolTip = 'The endpoint URL of your Azure Cosmos DB account (e.g., https://your-account.documents.azure.com:443/)';
                }
                field("Database Name"; Rec."Database Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the database in Cosmos DB. Default: translations';
                }
                field("Container Name"; Rec."Container Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the container for BC corrections. Default: BCCorrections';
                }
                field("Cosmos Time Offset (Minutes)"; Rec."Cosmos Time Offset (Minutes)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Adjust the time used for Cosmos DB auth in minutes (negative if server time is ahead). Cosmos accepts only about +/- 15 minutes of skew.';
                }
                field(CosmosKeyStatus; GetCosmosKeyStatus())
                {
                    Caption = 'Cosmos Key Status';
                    ApplicationArea = All;
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = HasCosmosKey;
                    ToolTip = 'Indicates whether the Cosmos DB key is configured';
                }
            }
            group(CaptureSettings)
            {
                Caption = 'Capture Settings';

                field("Capture Shortcut"; Rec."Capture Shortcut")
                {
                    ApplicationArea = All;
                    ToolTip = 'Keyboard shortcut to capture text (e.g., Ctrl+Shift+F, Alt+T). Restart role center after change.';
                }
            }
            group(SyncSettings)
            {
                Caption = 'Sync Settings';

                field("Sync Enabled"; Rec."Sync Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable automatic synchronization of translation corrections to Cosmos DB';
                }
            }
            group(Status)
            {
                Caption = 'Last Sync Status';

                field("Last Sync DateTime"; Rec."Last Sync DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'The date and time of the last sync operation';
                }
                field("Last Sync Status"; Rec."Last Sync Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'The result of the last sync operation';
                }
                field("Records Synced"; Rec."Records Synced")
                {
                    ApplicationArea = All;
                    ToolTip = 'The number of records synced in the last operation';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetCosmosKey)
            {
                Caption = 'Set Cosmos Key';
                ApplicationArea = All;
                Image = EncryptionKeys;
                ToolTip = 'Set the Azure Cosmos DB primary key (stored securely)';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    if Page.RunModal(Page::"Set Cosmos Key Dialog") = Action::LookupOK then begin
                        CurrPage.Update(false);
                        Message('Cosmos DB key has been saved securely.');
                    end;
                end;
            }
            action(TestConnection)
            {
                Caption = 'Test Connection';
                ApplicationArea = All;
                Image = TestDatabase;
                ToolTip = 'Test the connection to Azure Cosmos DB';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TranslationSync: Codeunit TranslationSync;
                begin
                    if TranslationSync.TestConnection() then
                        Message('Connection successful!')
                    else
                        Error('Connection failed. Please check your endpoint and key.');
                end;
            }
            action(SyncNow)
            {
                Caption = 'Sync Now';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Manually run the sync operation now';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TranslationSync: Codeunit TranslationSync;
                begin
                    if TranslationSync.RunSyncManual() then
                        Message('Sync completed successfully.')
                    else
                        Message('Sync completed with errors. Check Last Sync Status for details.');
                    CurrPage.Update(false);
                end;
            }
            action(SetupJobQueue)
            {
                Caption = 'Setup Job Queue';
                ApplicationArea = All;
                Image = JobTimeSheet;
                ToolTip = 'Create or update the Job Queue entry for automatic daily sync';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TranslationSyncJobQueue: Codeunit TranslationSyncJobQueue;
                begin
                    TranslationSyncJobQueue.CreateOrUpdateJobQueueEntry();
                end;
            }
            action(ClearCosmosKey)
            {
                Caption = 'Clear Cosmos Key';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Remove the stored Cosmos DB key';

                trigger OnAction()
                var
                    CosmosCredentials: Codeunit CosmosCredentials;
                begin
                    if Confirm('Are you sure you want to clear the Cosmos DB key?') then begin
                        CosmosCredentials.ClearCosmosKey();
                        CurrPage.Update(false);
                        Message('Cosmos DB key has been cleared.');
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        HasCosmosKey: Boolean;

    local procedure GetCosmosKeyStatus(): Text
    var
        CosmosCredentials: Codeunit CosmosCredentials;
    begin
        HasCosmosKey := CosmosCredentials.HasCosmosKey();
        if HasCosmosKey then
            exit('Configured')
        else
            exit('Not configured');
    end;
}
