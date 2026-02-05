namespace Forey.ALTranslation;

table 95000 TranslationDB
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Translated Text"; Text[250])
        {
            Caption = 'Translated Text';
        }
        field(3; "Area of text"; Text[100])
        {
            Caption = 'Area of text';
        }
        field(4; "Corrected Translation"; Text[250])
        {
            Caption = 'Corrected Translation';
        }
        field(5; "Page ID"; Integer)
        {
            Caption = 'Page ID';
        }
        field(10; Synced; Boolean)
        {
            Caption = 'Synced';
            DataClassification = SystemMetadata;
        }
        field(11; "Synced DateTime"; DateTime)
        {
            Caption = 'Synced DateTime';
            DataClassification = SystemMetadata;
        }
        field(12; "Cosmos Document ID"; Text[100])
        {
            Caption = 'Cosmos Document ID';
            DataClassification = SystemMetadata;
        }
        // Element identification fields
        field(20; "Element Type"; Text[50])
        {
            Caption = 'Element Type';
            // Field, Action, Menu, Tab, Column, Unknown
        }
        field(21; "Property Type"; Text[20])
        {
            Caption = 'Property Type';
            // Caption, ToolTip
        }
        field(22; "UI Area"; Text[50])
        {
            Caption = 'UI Area';
            // Ribbon, List, Dialog, Content, FactBox
        }
        field(23; "HTML Tag"; Text[50])
        {
            Caption = 'HTML Tag';
        }
        field(24; "ARIA Role"; Text[50])
        {
            Caption = 'ARIA Role';
        }
        field(25; "ARIA Label"; Text[250])
        {
            Caption = 'ARIA Label';
        }
        field(26; "Title Attribute"; Text[250])
        {
            Caption = 'Title Attribute';
        }
        field(27; "Element ID"; Text[100])
        {
            Caption = 'Element ID';
        }
        field(28; "Element Name"; Text[100])
        {
            Caption = 'Element Name';
        }
        field(29; "CSS Classes"; Text[500])
        {
            Caption = 'CSS Classes';
        }
        field(30; "Parent Chain"; Text[1000])
        {
            Caption = 'Parent Chain';
            // JSON array of parent element info
        }
        field(31; "Data Attributes"; Text[1000])
        {
            Caption = 'Data Attributes';
            // JSON object of data-* attributes
        }
        field(32; "Selector Path"; Text[500])
        {
            Caption = 'Selector Path';
            // CSS selector path to element
        }
        field(33; "Inner Text"; Text[500])
        {
            Caption = 'Inner Text';
            // Full inner text (may differ from captured text)
        }
        field(34; "Placeholder"; Text[250])
        {
            Caption = 'Placeholder';
        }
        field(35; "Is ToolTip"; Boolean)
        {
            Caption = 'Is ToolTip';
            // True if captured from tooltip/title
        }
        field(36; "Frame Index"; Integer)
        {
            Caption = 'Frame Index';
            // Which iframe the element was in
        }
        field(37; "Page Name"; Text[100])
        {
            Caption = 'Page Name';
            // English page object name for XLIFF matching
        }
        // BC metadata fields for precise XLIFF matching
        field(40; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            // The table ID that the page/field is bound to
        }
        field(41; "Table Field No."; Integer)
        {
            Caption = 'Table Field No.';
            // The field number within the source table
        }
        field(42; "BC Field Name"; Text[100])
        {
            Caption = 'BC Field Name';
            // The English field name from BC metadata
        }
        field(43; "Table Name"; Text[100])
        {
            Caption = 'Table Name';
            // The English table name (looked up from Table Metadata)
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

}