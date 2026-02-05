namespace Forey.ALTranslation;

page 95003 "Set Cosmos Key Dialog"
{
    Caption = 'Set Cosmos DB Key';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            group(KeyInput)
            {
                Caption = 'Enter Cosmos DB Primary Key';

                field(CosmosKey; CosmosKeyValue)
                {
                    Caption = 'Cosmos DB Key';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Enter your Azure Cosmos DB primary or secondary key';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CosmosCredentials: Codeunit CosmosCredentials;
    begin
        if CloseAction = Action::LookupOK then begin
            if CosmosKeyValue = '' then
                Error('Please enter a Cosmos DB key.');
            CosmosCredentials.SetCosmosKey(CosmosKeyValue);
        end;
        exit(true);
    end;

    var
        CosmosKeyValue: Text[500];
}
