namespace Forey.ALTranslation;

page 95004 TranslatorRoleCenter
{
    Caption = 'Translator';
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
            part(TranslatorControl; TranslatorSubpage)
            {
                ApplicationArea = All;
                Caption = '';
            }
            part(Translations; TranslationsListPart)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Embedding)
        {
            action(TranslationList)
            {
                Caption = 'Translations';
                ApplicationArea = All;
                RunObject = page TranslationList;
                ToolTip = 'View and manage captured translations';
            }
        }
        area(Processing)
        {
            action(Setup)
            {
                Caption = 'Translation Setup';
                ApplicationArea = All;
                RunObject = page TranslationSetup;
                Image = Setup;
                ToolTip = 'Configure Cosmos DB sync settings';
            }
        }
    }
}
