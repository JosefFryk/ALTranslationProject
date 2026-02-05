# ALTranslationProject Recap

## Project Overview

A Business Central AL extension for capturing and managing translation corrections directly from the BC web client UI, with automatic sync to Azure Cosmos DB.

**Target Platform**: Business Central 25.0 (Runtime 14.0)
**ID Range**: 95000-95149
**Namespace**: `Forey.ALTranslation`

## What Has Been Built

### 1. Control Add-in for Text Capture

**File**: `src/al/ControlAddin/Translator.ControlAddin.al`

A JavaScript-based control add-in that:
- Listens for configurable keyboard shortcut (default: `Ctrl+Shift+F`) across all iframes in BC web client
- Captures text under the mouse cursor (aria-label, innerText, title attributes)
- Detects the current page title and page ID from URL
- Shows a styled dialog for entering corrected translations
- Shortcut is configurable in Translation Setup page

### 2. Translation Database

**File**: `src/al/Table/TranslationDB.Table.al` (Table 95000)

| Field | Type | Description |
|-------|------|-------------|
| Entry No. | Integer | Auto-increment PK |
| Translated Text | Text[250] | Captured original text |
| Area of text | Text[100] | Page/area where captured |
| Corrected Translation | Text[250] | User-provided correction |
| Page ID | Integer | BC page ID |
| Synced | Boolean | Whether synced to Cosmos DB |
| Synced DateTime | DateTime | When synced |
| Cosmos Document ID | Text[100] | Document ID in Cosmos DB |

### 3. Translation Setup

**File**: `src/al/Table/TranslationSetup.Table.al` (Table 95001)

| Field | Description |
|-------|-------------|
| Cosmos DB Endpoint | Azure Cosmos DB endpoint URL |
| Database Name | Default: `corrections` |
| Container Name | Default: `activa_corrections` |
| Cosmos Time Offset (Minutes) | Adjust time for Cosmos DB auth |
| Capture Shortcut | Keyboard shortcut for capture (default: `Ctrl+Shift+F`) |
| Sync Enabled | Enable/disable automatic sync |
| Last Sync DateTime | When last sync ran |
| Last Sync Status | Result of last sync |
| Records Synced | Count of synced records |

### 4. Azure Cosmos DB Integration

#### CosmosCredentials (Codeunit 95002)
Secure credential management using IsolatedStorage:
- `SetCosmosKey()` / `GetCosmosKey()` / `HasCosmosKey()` / `ClearCosmosKey()`
- `IsConfigured()` - validates endpoint + key are set

#### CosmosDBClient (Codeunit 95003)
HTTP client for Cosmos DB REST API:
- HMAC-SHA256 authentication using `GenerateBase64KeyedHashAsBase64String`
- `CreateDocument()` - insert/upsert documents
- `TestConnection()` - validate credentials
- `CreateContainerIfNotExists()` - auto-create container

#### TranslationSync (Codeunit 95004)
Main sync logic:
- `RunSync()` - batch sync all unsynced records
- `SyncSingleRecord()` - sync individual record
- `TestConnection()` - validate setup

#### TranslationSyncJobQueue (Codeunit 95005)
Job Queue handler for scheduled daily sync:
- `CreateOrUpdateJobQueueEntry()` - setup job queue
- Runs weekdays at 2:00 AM

### 5. Cosmos DB Document Schema

```json
{
  "id": "BC-123",
  "source": "Účetní osnova",
  "target": "Účtová osnova",
  "sourceLang": "cs",
  "targetLang": "cs",
  "confidence": 1.0,
  "translationType": "UserCorrection",
  "pageId": 16,
  "area": "Účetní osnova - Card",
  "timestamp": "2025-01-04T10:00:00Z"
}
```

**Partition Key**: `/source`

### 6. Pages

| Page | ID | Purpose |
|------|----|---------|
| TranslatorRoleCenter | 95004 | Dedicated role center for translation work |
| TranslatorSubpage | 95000 | Control add-in host (CardPart) |
| TranslationList | 95001 | List/manage translations with sync status |
| TranslationSetup | 95002 | Configure Cosmos DB connection |
| Set Cosmos Key Dialog | 95003 | Secure key entry dialog |
| TranslationsListPart | 95006 | ListPart with translations and sync actions |

### 7. Dedicated Translator Role

**File**: `src/al/Profile/Translator.Profile.al`

A dedicated role for translation work:
- Users switch to this role only when translating
- Role center includes the translator control add-in
- No need to extend other role centers

The role center layout:
1. **TranslatorControl** - The capture control add-in
2. **Translations** - ListPart with sync actions (Sync All, Sync Selected, Open Full List, Setup)

### 8. JavaScript Components

| File | Purpose |
|------|---------|
| `translator.js` | Main capture logic, frame listeners, cursor tracking |
| `dialog.js` | Modal dialog for translation input |
| `start.js` | Initialization entry point |

### 9. CSS Styling

- `TranslatorButton.css` - Indicator button styling (on/off states)
- `dialog.css` - Modal dialog styling

## How to Use

### Setup
1. Switch to **Translator** role (or assign it to a user)
2. Open **Translation Setup** page
3. Enter Cosmos DB Endpoint (e.g., `https://your-account.documents.azure.com:443/`)
4. Click **Set Cosmos Key** → enter primary key
5. Click **Test Connection** to verify
6. Enable **Sync Enabled**
7. (Optional) Change **Capture Shortcut** (default: `Ctrl+Shift+F`)
8. Click **Setup Job Queue** for automatic daily sync

### Capturing Corrections
1. Switch to **Translator** role
2. Navigate to any BC page from the role center
3. Hover over incorrectly translated text
4. Press the configured shortcut (default: `Ctrl+Shift+F`)
5. Enter corrected translation in dialog
6. Click OK
7. If same text is captured again, a new record is created (duplicates allowed, last correction wins)

### Syncing to Cosmos DB
- **Manual**: Click **Sync Now** in Translation Setup
- **Selected**: Select records in Translations list → **Sync Selected**
- **Automatic**: Job Queue runs daily at 2:00 AM

## File Summary

```
src/al/
├── Table/
│   ├── TranslationDB.Table.al          (95000)
│   └── TranslationSetup.Table.al       (95001)
├── Page/
│   ├── TranslatorSubpage.Page.al       (95000)
│   ├── TranslationList.Page.al         (95001)
│   ├── TranslationSetup.Page.al        (95002)
│   ├── SetCosmosKeyDialog.Page.al      (95003)
│   ├── TranslatorRoleCenter.Page.al    (95004)
│   └── TranslationsListPart.Page.al    (95006)
├── Codeunit/
│   ├── Translator.Codeunit.al          (95000)
│   ├── CosmosCredentials.Codeunit.al   (95002)
│   ├── CosmosDBClient.Codeunit.al      (95003)
│   ├── TranslationSync.Codeunit.al     (95004)
│   └── TranslationSyncJobQueue.Codeunit.al (95005)
├── ControlAddin/
│   └── Translator.ControlAddin.al
└── Profile/
    └── Translator.Profile.al
```

## Relationship Between Projects

| Project | Purpose |
|---------|---------|
| **ALTranslationProject** | BC extension to capture translation errors from live UI |
| **ALHiLoExtension** | VS Code extension to translate XLIFF files with AI |

The workflow:
1. User switches to **Translator** role in BC
2. Capture bad translations → saved to TranslationDB
3. Sync corrections to Azure Cosmos DB (`corrections` / `activa_corrections`)
4. ALHiLoExtension can query Cosmos DB for corrections during XLIFF translation
5. Developer applies corrections to XLIFF source files
6. Deploy corrected app with improved translations
7. If same text captured again, new record created (last correction wins in Cosmos)
