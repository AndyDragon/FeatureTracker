export const applicationName = "Feature Tracker";
export const applicationDescription = "Feature Tracker is a small utility app to track Vero features.";
export const applicationDetails = (
    <>
        This utility lets you track your snap hub features on Vero and will calculate what your membership level should be
        based on the feature count and pages with a feature count. This includes multiple point features and challenges.
    </>
);
export const macScreenshotWidth = 1024;
export const macScreenshotHeight = 630;

export const deploymentWebLocation = "/app/featuretracker";

export const versionLocation = "featuretracker/version.json";

export const macDmgLocation = "featuretracker/macos/Feature%20Tracker%20";
export const macReleaseNotesLocation = "releaseNotes-mac.json";

export const windowsInstallerLocation = "featuretracker/windows";
export const windowsReleaseNotesLocation = "releaseNotes-windows.json";

export type Platform = "macOS" | "windows";

export const platformString: Record<Platform, string> = {
    macOS: "macOS",
    windows: "Windows"
}

export interface Links {
    readonly location: (version: string, flavorSuffix: string) => string;
    readonly actions: {
        readonly name: string;
        readonly action: string;
        readonly target: string;
        readonly suffix: string;
    }[];
}

export const links: Record<Platform, Links | undefined> = {
    macOS: {
        location: (version, suffix) => `${macDmgLocation}${suffix}v${version}.dmg`,
        actions: [
            {
                name: "default",
                action: "download",
                target: "",
                suffix: "",
            },
            {
                name: "cloud sync w/ iCloud",
                action: "download",
                target: "",
                suffix: "with%20CloudSync%20"
            }
        ]
    },
    windows: {
        location: (_version, suffix) => `${windowsInstallerLocation}${suffix}`,
        actions: [
            {
                name: "current",
                action: "install",
                target: "",
                suffix: "/setup.exe",
            },
            {
                name: "current",
                action: "read more about",
                target: "_blank",
                suffix: "",
            }
        ]
    },
};
