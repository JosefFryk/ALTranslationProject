namespace Forey.ALTranslation;

codeunit 95004 TranslationSync
{
    var
        CosmosClient: Codeunit CosmosDBClient;
        CosmosCredentials: Codeunit CosmosCredentials;

    procedure RunSync(): Boolean
    begin
        exit(RunSyncInternal(true));
    end;

    procedure RunSyncManual(): Boolean
    begin
        exit(RunSyncInternal(false));
    end;

    local procedure RunSyncInternal(EnforceSyncEnabled: Boolean): Boolean
    var
        TranslationSetup: Record TranslationSetup;
        SyncedCount: Integer;
        ErrorCount: Integer;
    begin
        if not TranslationSetup.GetSetup() then
            exit(false);

        if EnforceSyncEnabled and not TranslationSetup."Sync Enabled" then
            exit(false);

        if not CosmosCredentials.IsConfigured() then begin
            UpdateSyncStatus(TranslationSetup, 'Error: Cosmos DB not configured', 0);
            exit(false);
        end;

        InitializeClient(TranslationSetup);

        // Ensure container exists
        if not CosmosClient.CreateContainerIfNotExists(
            TranslationSetup."Database Name",
            TranslationSetup."Container Name",
            '/source') then begin
            UpdateSyncStatus(TranslationSetup, 'Error: Failed to create container', 0);
            exit(false);
        end;

        SyncPendingRecords(TranslationSetup, SyncedCount, ErrorCount);

        if ErrorCount > 0 then
            UpdateSyncStatus(TranslationSetup, StrSubstNo('Completed with errors: %1 synced, %2 failed', SyncedCount, ErrorCount), SyncedCount)
        else
            UpdateSyncStatus(TranslationSetup, StrSubstNo('Success: %1 records synced', SyncedCount), SyncedCount);

        exit(ErrorCount = 0);
    end;

    procedure SyncSingleRecord(var TranslationDB: Record TranslationDB): Boolean
    var
        TranslationSetup: Record TranslationSetup;
        JsonDocument: Text;
    begin
        if not TranslationSetup.GetSetup() then
            exit(false);

        if not CosmosCredentials.IsConfigured() then
            exit(false);

        InitializeClient(TranslationSetup);

        JsonDocument := BuildJsonDocument(TranslationDB, TranslationSetup."Container Name");

        if CosmosClient.CreateDocument(
            TranslationSetup."Database Name",
            TranslationSetup."Container Name",
            JsonDocument,
            TranslationDB."Translated Text") then begin
            MarkAsSynced(TranslationDB);
            exit(true);
        end;

        exit(false);
    end;

    local procedure SyncPendingRecords(var TranslationSetup: Record TranslationSetup; var SyncedCount: Integer; var ErrorCount: Integer)
    var
        TranslationDB: Record TranslationDB;
        JsonDocument: Text;
    begin
        SyncedCount := 0;
        ErrorCount := 0;

        TranslationDB.SetRange(Synced, false);
        TranslationDB.SetFilter("Corrected Translation", '<>%1', '');

        if TranslationDB.FindSet() then
            repeat
                JsonDocument := BuildJsonDocument(TranslationDB, TranslationSetup."Container Name");

                if CosmosClient.CreateDocument(
                    TranslationSetup."Database Name",
                    TranslationSetup."Container Name",
                    JsonDocument,
                    TranslationDB."Translated Text") then begin
                    MarkAsSynced(TranslationDB);
                    SyncedCount += 1;
                end else
                    ErrorCount += 1;

                Commit();
            until TranslationDB.Next() = 0;
    end;

    local procedure BuildJsonDocument(TranslationDB: Record TranslationDB; ContainerName: Text): Text
    var
        JsonObj: JsonObject;
        ElementContextObj: JsonObject;
        JsonText: Text;
    begin
        JsonObj.Add('id', StrSubstNo('BC-%1', TranslationDB."Entry No."));
        JsonObj.Add('source', TranslationDB."Translated Text");
        JsonObj.Add('target', TranslationDB."Corrected Translation");
        JsonObj.Add('sourceLang', 'cs');
        JsonObj.Add('targetLang', 'cs');
        JsonObj.Add('confidence', 1.0);
        JsonObj.Add('sourceDatabase', ContainerName);
        JsonObj.Add('translationType', 'UserCorrection');
        JsonObj.Add('timestamp', Format(CurrentDateTime, 0, 9)); // ISO 8601
        JsonObj.Add('pageId', TranslationDB."Page ID");
        JsonObj.Add('pageName', TranslationDB."Page Name");
        JsonObj.Add('area', TranslationDB."Area of text");
        // BC metadata for precise XLIFF matching
        if TranslationDB."Source Table ID" <> 0 then
            JsonObj.Add('sourceTableId', TranslationDB."Source Table ID");
        if TranslationDB."Table Field No." <> 0 then
            JsonObj.Add('tableFieldNo', TranslationDB."Table Field No.");
        if TranslationDB."BC Field Name" <> '' then
            JsonObj.Add('bcFieldName', TranslationDB."BC Field Name");
        if TranslationDB."Table Name" <> '' then
            JsonObj.Add('tableName', TranslationDB."Table Name");

        // Element context for XLIFF matching
        ElementContextObj.Add('elementType', TranslationDB."Element Type");
        ElementContextObj.Add('propertyType', TranslationDB."Property Type");
        ElementContextObj.Add('uiArea', TranslationDB."UI Area");
        ElementContextObj.Add('htmlTag', TranslationDB."HTML Tag");
        ElementContextObj.Add('ariaRole', TranslationDB."ARIA Role");
        ElementContextObj.Add('ariaLabel', TranslationDB."ARIA Label");
        ElementContextObj.Add('titleAttribute', TranslationDB."Title Attribute");
        ElementContextObj.Add('elementId', TranslationDB."Element ID");
        ElementContextObj.Add('elementName', TranslationDB."Element Name");
        ElementContextObj.Add('cssClasses', TranslationDB."CSS Classes");
        ElementContextObj.Add('selectorPath', TranslationDB."Selector Path");
        ElementContextObj.Add('innerText', TranslationDB."Inner Text");
        ElementContextObj.Add('placeholder', TranslationDB.Placeholder);
        ElementContextObj.Add('isToolTip', TranslationDB."Is ToolTip");
        ElementContextObj.Add('frameIndex', TranslationDB."Frame Index");
        // Parent chain and data attributes are already JSON strings
        if TranslationDB."Parent Chain" <> '' then
            ElementContextObj.Add('parentChain', TranslationDB."Parent Chain");
        if TranslationDB."Data Attributes" <> '' then
            ElementContextObj.Add('dataAttributes', TranslationDB."Data Attributes");

        JsonObj.Add('elementContext', ElementContextObj);

        JsonObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure MarkAsSynced(var TranslationDB: Record TranslationDB)
    begin
        TranslationDB.Synced := true;
        TranslationDB."Synced DateTime" := CurrentDateTime;
        TranslationDB."Cosmos Document ID" := StrSubstNo('BC-%1', TranslationDB."Entry No.");
        TranslationDB.Modify(true);
    end;

    local procedure InitializeClient(TranslationSetup: Record TranslationSetup)
    begin
        CosmosClient.Initialize(
            TranslationSetup."Cosmos DB Endpoint",
            CosmosCredentials.GetCosmosKey(),
            TranslationSetup."Cosmos Time Offset (Minutes)");
    end;

    local procedure UpdateSyncStatus(var TranslationSetup: Record TranslationSetup; Status: Text; RecordsSynced: Integer)
    begin
        TranslationSetup."Last Sync DateTime" := CurrentDateTime;
        TranslationSetup."Last Sync Status" := CopyStr(Status, 1, MaxStrLen(TranslationSetup."Last Sync Status"));
        TranslationSetup."Records Synced" := RecordsSynced;
        TranslationSetup.Modify(true);
    end;

    procedure TestConnection(): Boolean
    var
        TranslationSetup: Record TranslationSetup;
    begin
        if not TranslationSetup.GetSetup() then
            exit(false);

        if not CosmosCredentials.IsConfigured() then
            exit(false);

        InitializeClient(TranslationSetup);
        exit(CosmosClient.TestConnection(TranslationSetup."Database Name"));
    end;
}
