import {setGlobalOptions} from "firebase-functions/v2";

import {REGION} from "./config";

setGlobalOptions({region: REGION, maxInstances: 10});

export {addStudents} from "./callables/addStudents";
export {claimAccount} from "./callables/claimAccount";
export {deleteMyAccount} from "./callables/deleteMyAccount";
export {eraseStudent} from "./callables/eraseStudent";
export {removeStudent} from "./callables/removeStudent";

export {dailyRefresh} from "./scheduled/dailyRefresh";

export {onCommentCreated} from "./triggers/onCommentCreated";
export {onJournalWritten} from "./triggers/onJournalWritten";
export {onProgramWritten} from "./triggers/onProgramWritten";
export {onSchoolUpdated} from "./triggers/onSchoolChanges";
export {onUserUpdated} from "./triggers/onUserUpdated";
