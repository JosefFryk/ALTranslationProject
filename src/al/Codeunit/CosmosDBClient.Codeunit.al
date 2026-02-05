namespace Forey.ALTranslation;

using System.Security.Encryption;
using System.Reflection;
using System.Text;

codeunit 95003 CosmosDBClient
{
    var
        Endpoint: Text;
        MasterKey: SecretText;
        IsInitialized: Boolean;
        TimeOffsetMinutes: Integer;

    procedure Initialize(NewEndpoint: Text; NewKey: SecretText; NewTimeOffsetMinutes: Integer)
    begin
        // Remove trailing slash from endpoint to avoid double slashes in URLs
        Endpoint := NewEndpoint;
        if Endpoint.EndsWith('/') then
            Endpoint := CopyStr(Endpoint, 1, StrLen(Endpoint) - 1);
        MasterKey := NewKey;
        TimeOffsetMinutes := NewTimeOffsetMinutes;
        IsInitialized := true;
    end;

    procedure CreateDocument(DatabaseId: Text; ContainerId: Text; JsonDocument: Text; PartitionKey: Text): Boolean
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        Url: Text;
        EncodedDatabaseId: Text;
        EncodedContainerId: Text;
        DateHeader: Text;
        AuthHeader: Text;
        ResponseText: Text;
        ResolvedPartitionKey: Text;
    begin
        if not IsInitialized then
            Error('CosmosDBClient not initialized. Call Initialize first.');

        EncodedDatabaseId := EncodeUrlPathSegment(DatabaseId);
        EncodedContainerId := EncodeUrlPathSegment(ContainerId);
        Url := StrSubstNo('%1/dbs/%2/colls/%3/docs', Endpoint, EncodedDatabaseId, EncodedContainerId);
        DateHeader := GetUtcDate();

        AuthHeader := GenerateAuthToken('POST', 'docs', StrSubstNo('dbs/%1/colls/%2', DatabaseId, ContainerId), DateHeader);

        Request.Method := 'POST';
        Request.SetRequestUri(Url);
        Request.GetHeaders(Headers);
        Headers.Add('Authorization', AuthHeader);
        Headers.Add('x-ms-date', DateHeader);
        Headers.Add('x-ms-version', '2020-07-15');
        if TryGetPartitionKeyFromDocument(JsonDocument, ResolvedPartitionKey) then
            Headers.Add('x-ms-documentdb-partitionkey', BuildPartitionKeyHeader(ResolvedPartitionKey))
        else
            Headers.Add('x-ms-documentdb-partitionkey', BuildPartitionKeyHeader(PartitionKey));

        Content.WriteFrom(JsonDocument);
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Request.Content := Content;

        if not Client.Send(Request, Response) then begin
            Error('Failed to send request to Cosmos DB');
            exit(false);
        end;

        Response.Content.ReadAs(ResponseText);

        if not Response.IsSuccessStatusCode then begin
            if Response.HttpStatusCode = 409 then
                exit(true); // Document already exists, treat as success
            Error('Cosmos DB error: %1 - %2', Response.HttpStatusCode, ResponseText);
            exit(false);
        end;

        exit(true);
    end;

    procedure TestConnection(DatabaseId: Text): Boolean
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Url: Text;
        EncodedDatabaseId: Text;
        DateHeader: Text;
        AuthHeader: Text;
    begin
        if not IsInitialized then
            exit(false);

        EncodedDatabaseId := EncodeUrlPathSegment(DatabaseId);
        Url := StrSubstNo('%1/dbs/%2', Endpoint, EncodedDatabaseId);
        DateHeader := GetUtcDate();

        AuthHeader := GenerateAuthToken('GET', 'dbs', StrSubstNo('dbs/%1', DatabaseId), DateHeader);

        Request.Method := 'GET';
        Request.SetRequestUri(Url);
        Request.GetHeaders(Headers);
        Headers.Add('Authorization', AuthHeader);
        Headers.Add('x-ms-date', DateHeader);
        Headers.Add('x-ms-version', '2020-07-15');

        if not Client.Send(Request, Response) then
            exit(false);

        exit(Response.IsSuccessStatusCode);
    end;

    procedure CreateContainerIfNotExists(DatabaseId: Text; ContainerId: Text; PartitionKeyPath: Text): Boolean
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        Url: Text;
        EncodedDatabaseId: Text;
        DateHeader: Text;
        AuthHeader: Text;
        JsonBody: Text;
    begin
        if not IsInitialized then
            exit(false);

        EncodedDatabaseId := EncodeUrlPathSegment(DatabaseId);
        Url := StrSubstNo('%1/dbs/%2/colls', Endpoint, EncodedDatabaseId);
        DateHeader := GetUtcDate();

        AuthHeader := GenerateAuthToken('POST', 'colls', StrSubstNo('dbs/%1', DatabaseId), DateHeader);

        JsonBody := StrSubstNo('{"id":"%1","partitionKey":{"paths":["%2"],"kind":"Hash"}}', ContainerId, PartitionKeyPath);

        Request.Method := 'POST';
        Request.SetRequestUri(Url);
        Request.GetHeaders(Headers);
        Headers.Add('Authorization', AuthHeader);
        Headers.Add('x-ms-date', DateHeader);
        Headers.Add('x-ms-version', '2020-07-15');

        Content.WriteFrom(JsonBody);
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Request.Content := Content;

        if not Client.Send(Request, Response) then
            exit(false);

        // 201 = Created, 409 = Already exists (both are fine)
        exit(Response.IsSuccessStatusCode or (Response.HttpStatusCode = 409));
    end;

    local procedure EncodeUrlPathSegment(Value: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.UrlEncode(Value));
    end;

    local procedure GenerateAuthToken(Verb: Text; ResourceType: Text; ResourceId: Text; DateHeader: Text): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        StringToSign: Text;
        Signature: Text;
        AuthToken: Text;
        LF: Char;
    begin
        LF := 10; // Line feed character

        // Cosmos DB signature format: verb\nresourceType\nresourceLink\ndate\n\n
        // verb, resourceType, date = lowercase
        // resourceLink = case-sensitive (keep as-is)
        StringToSign := LowerCase(Verb) + Format(LF) +
                        LowerCase(ResourceType) + Format(LF) +
                        ResourceId + Format(LF) +
                        LowerCase(DateHeader) + Format(LF) +
                        Format(LF);

        // Cosmos DB master key is Base64 encoded - use GenerateBase64KeyedHashAsBase64String
        // which accepts Base64-encoded key as SecretText directly
        Signature := CryptographyMgt.GenerateBase64KeyedHashAsBase64String(StringToSign, MasterKey, 2); // 2 = HMACSHA256

        AuthToken := StrSubstNo('type=master&ver=1.0&sig=%1', Signature);
        exit(EncodeUri(AuthToken));
    end;

    local procedure GetUtcDate(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        UtcDateTime: DateTime;
        TimeOffset: Duration;
        UtcDate: Date;
        UtcTime: Time;
        WeekDay: Integer;
        WeekDayName: Text;
        MonthName: Text;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        Hour: Integer;
        Minute: Integer;
        Second: Integer;
    begin
        // RFC 1123 format requires English: "Sun, 04 Jan 2026 16:17:34 GMT"
        UtcDateTime := TypeHelper.GetCurrUTCDateTime();
        if TimeOffsetMinutes <> 0 then begin
            TimeOffset := TimeOffsetMinutes * 60000;
            UtcDateTime := UtcDateTime + TimeOffset;
        end;
        UtcDate := DT2Date(UtcDateTime);
        UtcTime := DT2Time(UtcDateTime);

        WeekDay := Date2DWY(UtcDate, 1); // 1=Mon, 2=Tue, ..., 7=Sun
        Day := Date2DMY(UtcDate, 1);
        Month := Date2DMY(UtcDate, 2);
        Year := Date2DMY(UtcDate, 3);

        // Extract time components using Format
        Evaluate(Hour, Format(UtcTime, 0, '<Hours24>'));
        Evaluate(Minute, Format(UtcTime, 0, '<Minutes>'));
        Evaluate(Second, Format(UtcTime, 0, '<Seconds>'));

        // English weekday names
        case WeekDay of
            1:
                WeekDayName := 'Mon';
            2:
                WeekDayName := 'Tue';
            3:
                WeekDayName := 'Wed';
            4:
                WeekDayName := 'Thu';
            5:
                WeekDayName := 'Fri';
            6:
                WeekDayName := 'Sat';
            7:
                WeekDayName := 'Sun';
        end;

        // English month names
        case Month of
            1:
                MonthName := 'Jan';
            2:
                MonthName := 'Feb';
            3:
                MonthName := 'Mar';
            4:
                MonthName := 'Apr';
            5:
                MonthName := 'May';
            6:
                MonthName := 'Jun';
            7:
                MonthName := 'Jul';
            8:
                MonthName := 'Aug';
            9:
                MonthName := 'Sep';
            10:
                MonthName := 'Oct';
            11:
                MonthName := 'Nov';
            12:
                MonthName := 'Dec';
        end;

        exit(StrSubstNo('%1, %2 %3 %4 %5:%6:%7 GMT',
            WeekDayName,
            PadStr('', 2 - StrLen(Format(Day)), '0') + Format(Day),
            MonthName,
            Year,
            PadStr('', 2 - StrLen(Format(Hour)), '0') + Format(Hour),
            PadStr('', 2 - StrLen(Format(Minute)), '0') + Format(Minute),
            PadStr('', 2 - StrLen(Format(Second)), '0') + Format(Second)));
    end;

    [TryFunction]
    local procedure TryGetPartitionKeyFromDocument(JsonDocument: Text; var PartitionKeyOut: Text)
    var
        JsonObj: JsonObject;
        Tok: JsonToken;
    begin
        JsonObj.ReadFrom(JsonDocument);
        if JsonObj.Get('source', Tok) then
            PartitionKeyOut := Tok.AsValue().AsText();
    end;

    local procedure BuildPartitionKeyHeader(PartitionKey: Text): Text
    var
        JsonArray: JsonArray;
        JsonText: Text;
    begin
        // Use JSON encoding to preserve exact value.
        JsonArray.Add(PartitionKey);
        JsonArray.WriteTo(JsonText);
        exit(EscapeHeaderJson(JsonText));
    end;

    local procedure EscapeHeaderJson(JsonText: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        i: Integer;
        Ch: Char;
        CodePoint: Integer;
        HexValue: Text;
        ResultText: Text;
    begin
        // Convert non-ASCII characters to \uXXXX so the header stays ASCII-only.
        for i := 1 to StrLen(JsonText) do begin
            Ch := JsonText[i];
            CodePoint := Ch;
            if (CodePoint < 32) or (CodePoint > 126) then begin
                HexValue := UpperCase(TypeHelper.IntToHex(CodePoint));
                HexValue := PadStr('', 4 - StrLen(HexValue), '0') + HexValue;
                ResultText += '\u' + HexValue;
            end else
                ResultText += Format(Ch);
        end;

        exit(ResultText);
    end;

    local procedure EncodeUri(Input: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.UrlEncode(Input));
    end;
}
