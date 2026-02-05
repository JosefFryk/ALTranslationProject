namespace Forey.ALTranslation;

codeunit 95002 CosmosCredentials
{
    var
        CosmosKeyLbl: Label 'CosmosDBKey', Locked = true;

    procedure SetCosmosKey(SecretValue: SecretText)
    begin
        if not EncryptionEnabled() then
            IsolatedStorage.Set(CosmosKeyLbl, SecretValue, DataScope::Company)
        else
            IsolatedStorage.SetEncrypted(CosmosKeyLbl, SecretValue, DataScope::Company);
    end;

    procedure GetCosmosKey(): SecretText
    var
        Value: SecretText;
        EmptySecret: SecretText;
    begin
        if IsolatedStorage.Get(CosmosKeyLbl, DataScope::Company, Value) then
            exit(Value);
        exit(EmptySecret);
    end;

    procedure HasCosmosKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(CosmosKeyLbl, DataScope::Company));
    end;

    procedure ClearCosmosKey()
    begin
        if IsolatedStorage.Contains(CosmosKeyLbl, DataScope::Company) then
            IsolatedStorage.Delete(CosmosKeyLbl, DataScope::Company);
    end;

    procedure IsConfigured(): Boolean
    var
        TranslationSetup: Record TranslationSetup;
    begin
        if not TranslationSetup.GetSetup() then
            exit(false);
        if TranslationSetup."Cosmos DB Endpoint" = '' then
            exit(false);
        if not HasCosmosKey() then
            exit(false);
        exit(true);
    end;
}
