export interface VersionEntry {
    readonly current: string;
    readonly link: string;
    readonly vital: boolean;
  }

export interface Version {
    readonly macOS?: VersionEntry;
    readonly windows?: VersionEntry;
  }

export async function readVersion(versionLocation: string): Promise<Version> {
  let version: Version;
  try {
    const versionRequest = await fetch(
      "https://vero.andydragon.com/static/data/" + versionLocation,
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        cache: "no-cache",
      });
    version = await versionRequest.json();
  } catch (error) {
    console.warn("Failed to fetch the version data: " + JSON.stringify(error));
    version = {};
  }
  return version;
}
