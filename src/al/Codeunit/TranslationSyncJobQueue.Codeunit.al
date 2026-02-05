namespace Forey.ALTranslation;

using System.Threading;

codeunit 95005 TranslationSyncJobQueue
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        TranslationSync: Codeunit TranslationSync;
    begin
        TranslationSync.RunSync();
    end;

    procedure CreateOrUpdateJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryId: Guid;
    begin
        // Find existing job queue entry for this codeunit
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::TranslationSyncJobQueue);

        if JobQueueEntry.FindFirst() then begin
            // Update existing entry
            JobQueueEntry."Recurring Job" := true;
            JobQueueEntry."Run on Mondays" := true;
            JobQueueEntry."Run on Tuesdays" := true;
            JobQueueEntry."Run on Wednesdays" := true;
            JobQueueEntry."Run on Thursdays" := true;
            JobQueueEntry."Run on Fridays" := true;
            JobQueueEntry."Run on Saturdays" := false;
            JobQueueEntry."Run on Sundays" := false;
            JobQueueEntry."Starting Time" := 020000T; // 2:00 AM
            JobQueueEntry."No. of Minutes between Runs" := 0; // Daily, not minutes
            JobQueueEntry.Description := 'Translation Sync to Cosmos DB';
            JobQueueEntry.Modify(true);
        end else begin
            // Create new entry
            JobQueueEntry.Init();
            JobQueueEntry.ID := CreateGuid();
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := Codeunit::TranslationSyncJobQueue;
            JobQueueEntry."Recurring Job" := true;
            JobQueueEntry."Run on Mondays" := true;
            JobQueueEntry."Run on Tuesdays" := true;
            JobQueueEntry."Run on Wednesdays" := true;
            JobQueueEntry."Run on Thursdays" := true;
            JobQueueEntry."Run on Fridays" := true;
            JobQueueEntry."Run on Saturdays" := false;
            JobQueueEntry."Run on Sundays" := false;
            JobQueueEntry."Starting Time" := 020000T; // 2:00 AM
            JobQueueEntry."No. of Minutes between Runs" := 0;
            JobQueueEntry.Description := 'Translation Sync to Cosmos DB';
            JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
            JobQueueEntry.Insert(true);
        end;

        Message('Job Queue Entry created/updated. Set status to Ready when ready to run.');
    end;

    procedure SetJobQueueToReady()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::TranslationSyncJobQueue);

        if JobQueueEntry.FindFirst() then begin
            if JobQueueEntry.Status = JobQueueEntry.Status::"On Hold" then begin
                Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
                Message('Job Queue Entry set to Ready.');
            end else
                Message('Job Queue Entry is already active or in error state.');
        end else
            Message('Job Queue Entry not found. Please create it first.');
    end;
}
