import React from "react";
import { Platform, platformString } from "./config";
import { Version, readVersion } from "./version";
import { Body1, Body2, Spinner, Title2, makeStyles, shorthands } from "@fluentui/react-components";

export interface ReleaseNotesProps {
    readonly applicationName: string;
    readonly platform: Platform;
    readonly location: string;
    readonly versionLocation: string;
}

const useStyles = makeStyles({
    container: {
        "> div": { ...shorthands.padding("50px") },
    },
});

export default function ReleaseNotes(props: ReleaseNotesProps) {
    const { applicationName, platform, location, versionLocation } = props;

    const styles = useStyles();

    const [isReady, setIsReady] = React.useState(false);
    const [version, setVersion] = React.useState<Version | undefined>(undefined);
    const [releaseNotes, setReleaseNotes] = React.useState<VersionEntry[] | undefined>(undefined);

    React.useEffect(() => {
        const doLoad = async () => {
            setVersion(await readVersion(versionLocation));
            try {
                console.log("Fetching the release notes data from " + location);
                const releaseNotesRequest = await fetch(location, {
                    mode: 'no-cors',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    }
                });
                setReleaseNotes(await releaseNotesRequest.json());
            } catch (error) {
                console.warn("Failed to fetch the release notes data: '" + error + "' from " + location);
            }
            setTimeout(() => {
                setIsReady(true);
            }, 200);
        };
        versionLocation && location && doLoad();
    }, [versionLocation, location]);

    if (!isReady) {
        return (
            <div className={styles.container}>
                <Spinner appearance="primary" label="Loading..." />
            </div>
        );
    }

    if (!version?.[platform]?.current) {
        return (
            <div style={{ margin: "10px" }}>
                There is currently no version available for {platformString[platform]}. Check back at a later date for more information.
            </div>
        );
    }

    if (!releaseNotes) {
        return (
            <div style={{ margin: "10px" }}>
                There is currently no release notes available for {platformString[platform]}. Check back at a later date for more information.
            </div>
        );
    }

    const sortVersionEntries = (a: VersionEntry, b: VersionEntry) => {
        const versionA = a?.version?.toUpperCase() || "";
        const versionB = b?.version?.toUpperCase() || "";
        if (versionA > versionB) {
            return -1;
        }
        if (versionA < versionB) {
            return 1;
        }
        return 0;
    };
    const sortNoteEntries = (a: NoteEntry, b: NoteEntry) => {
        const dateA = new Date(a?.date) || Date.now;
        const dateB = new Date(b?.date) || Date.now;
        return dateA.getTime() - dateB.getTime();
    };
    let counter = 0;
    const renderedReleaseNotes = (releaseNotes.length &&
        releaseNotes.sort(sortVersionEntries).map((versionEntry) => {
            return (
                <div key={"ver-" + counter++}>
                    <br />
                    <Body2 style={{ fontFamily: "monospace" }}>Version {versionEntry.version}:</Body2>
                    {versionEntry.notes.sort(sortNoteEntries).map((note) => {
                        return (
                            <div key={"note-" + counter++} style={{ marginLeft: "20px" }}>
                                <Body1 style={{ fontFamily: "monospace" }}>{note.date}</Body1>
                                {note.notes.map((entry) => {
                                    return (
                                        <div key={"entry=" + counter++} style={{ marginLeft: "20px" }}>
                                            - {entry}
                                        </div>
                                    );
                                })}
                            </div>
                        );
                    })}
                </div>
            );
        })) || (
            <div>
                <br />
                There are no release notes to view
            </div>
        );

    return (
        <div style={{ margin: "40px" }}>
            <div style={{ fontFamily: "monospace" }}>
                <Title2 style={{ textDecoration: "underline", fontFamily: "monospace" }}>
                    Release notes for {applicationName} v{version?.[platform]?.current} for {platformString[platform]}
                </Title2>
                <div style={{ margin: "8px 20px" }}>{renderedReleaseNotes}</div>
            </div>
        </div>
    );
}

interface NoteEntry {
    readonly date: string;
    readonly notes: string[];
}

interface VersionEntry {
    readonly version: string;
    readonly notes: NoteEntry[];
}
