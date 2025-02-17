import React from "react";
import { Version, readVersion } from "./version";
import { Link, Spinner, Subtitle1, Subtitle2, makeStyles, shorthands } from "@fluentui/react-components";
import { Platform, links, platformString } from "./config";

export interface GeneralProps {
    readonly applicationName: string;
    readonly platform: Platform;
    readonly versionLocation: string;
}

const useStyles = makeStyles({
    container: {
        "> div": { ...shorthands.padding("50px") }
    },
    cleanLink: {
        ...shorthands.textDecoration("none"),
        color: "CornflowerBlue",
        "&:hover": {
            ...shorthands.textDecoration("underline"),
            color: "LightBlue",
        },
    },
});

export default function General(props: GeneralProps) {
    const { applicationName, platform, versionLocation } = props;
    const styles = useStyles();

    const [isReady, setIsReady] = React.useState(false);
    const [version, setVersion] = React.useState<Version | undefined>(undefined);

    React.useEffect(() => {
        const doLoad = async () => {
            setVersion(await readVersion(versionLocation));
            setTimeout(() => {
                setIsReady(true);
            }, 200);
        };
        doLoad();
    }, [versionLocation])

    if (!isReady) {
        return (
            <div className={styles.container}><Spinner appearance="primary" label="Loading..." /></div>
        );
    }

    const currentVersion = version?.[platform]?.current;
    if (!currentVersion && !links[platform]?.useAppStore) {
        return (
            <div style={{ margin: "10px" }}>
                There is currently no version available for {platformString[platform]}. Check back at a later date for more information.
            </div>
        );
    }

    let index = 0;

    const header = !links[platform]?.useAppStore
        ? (<><Subtitle1>{applicationName} v{currentVersion} for {platformString[platform]} is available for installation now.</Subtitle1><br /><br /></>)
        : (<><Subtitle1>{applicationName} for {platformString[platform]} is available for installation now.</Subtitle1><br /><br /></>);

    return (
        <div style={{ margin: "10px" }}>
            {header}
            {links[platform]?.actions.map(flavor => {
                const flavorVersion = (version?.[platform] as (Record<string, string> | undefined))?.["current"];
                if (!flavorVersion && currentVersion) {
                    return undefined;
                }
                const location = links[platform]?.useAppStore
                    ? links[platform]?.location(flavorVersion ?? "", flavor.suffix)
                    : "https://vero.andydragon.com/app/" + links[platform]?.location(flavorVersion ?? "", flavor.suffix);
                return (
                    <>
                        <Subtitle2 key={"link-" + (index++)} style={{ marginLeft: "40px" }}>You can {flavor.action} <Link target={flavor.target} href={location}>HERE</Link></Subtitle2>
                        <br /><br />
                    </>
                );
            })}
        </div>
    );
}