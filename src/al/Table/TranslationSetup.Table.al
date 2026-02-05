namespace Forey.ALTranslation;

table 95001 TranslationSetup
{
    Caption = 'Translation Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Cosmos DB Endpoint"; Text[250])
        {
            Caption = 'Cosmos DB Endpoint';
        }
        field(3; "Database Name"; Text[100])
        {
            Caption = 'Database Name';
            InitValue = 'corrections';
        }
        field(4; "Container Name"; Text[100])
        {
            Caption = 'Container Name';
            InitValue = 'activa_corrections';
        }
        field(5; "Sync Enabled"; Boolean)
        {
            Caption = 'Sync Enabled';
        }
        field(6; "Last Sync DateTime"; DateTime)
        {
            Caption = 'Last Sync DateTime';
            Editable = false;
        }
        field(7; "Last Sync Status"; Text[250])
        {
            Caption = 'Last Sync Status';
            Editable = false;
        }
        field(8; "Records Synced"; Integer)
        {
            Caption = 'Records Synced';
            Editable = false;
        }
        field(9; "Cosmos Time Offset (Minutes)"; Integer)
        {
            Caption = 'Cosmos Time Offset (Minutes)';
        }
        field(10; "Capture Shortcut"; Text[50])
        {
            Caption = 'Capture Shortcut';
            InitValue = 'Ctrl+Shift+F';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup(): Boolean
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
        exit(true);
    end;
}
