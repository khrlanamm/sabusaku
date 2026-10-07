import {setGlobalOptions} from "firebase-functions/v2";
import {onCall} from "firebase-functions/v2/https";

setGlobalOptions({region: "asia-southeast2", maxInstances: 10});

// Deploy smoke test. Remove once real functions exist.
export const ping = onCall(() => ({ok: true}));
