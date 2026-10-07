import {setGlobalOptions} from "firebase-functions/v2";

import {REGION} from "./config";

setGlobalOptions({region: REGION, maxInstances: 10});

export {createUsers} from "./callables/createUsers";
export {eraseStudent} from "./callables/eraseStudent";
export {moveStudentClass} from "./callables/moveStudentClass";
export {resetPassword} from "./callables/resetPassword";
export {setTeacherClasses} from "./callables/setTeacherClasses";
export {setUserActive} from "./callables/setUserActive";

export {dailyRefresh} from "./scheduled/dailyRefresh";

export {onCommentCreated} from "./triggers/onCommentCreated";
export {onJournalWritten} from "./triggers/onJournalWritten";
export {onProgramWritten} from "./triggers/onProgramWritten";
export {onClassUpdated, onSchoolUpdated} from "./triggers/onSchoolChanges";
export {onUserUpdated} from "./triggers/onUserUpdated";
