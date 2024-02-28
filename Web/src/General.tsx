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
    }
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
    if (!currentVersion) {
        return (
            <div style={{ margin: "10px" }}>
                There is currently no version available for {platformString[platform]}. Check back at a later date for more information.
            </div>
        );
    }

    let index = 0;

    return (
        <div style={{ margin: "10px" }}>
            <Subtitle1>{applicationName} v{currentVersion} is available for installation now for {platformString[platform]}.</Subtitle1><br /><br />
            {links[platform]?.actions.map(flavor => {
                const location = "https://vero.andydragon.com/app/" + links[platform]?.location(currentVersion, flavor.suffix);
                return (<><Subtitle2 key={"link-" + (index++)}>You can {flavor.action} the {flavor.name} version <Link target={flavor.target} href={location}>here</Link>.</Subtitle2><br /><br /></>);
            })}
        </div>
    );
}