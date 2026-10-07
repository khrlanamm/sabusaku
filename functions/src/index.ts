import {setGlobalOptions} from "firebase-functions/v2";

import {REGION} from "./config";

setGlobalOptions({region: REGION, maxInstances: 10});

export {createUsers} from "./callables/createUsers";
export {eraseStudent} from "./callables/eraseStudent";
export {moveStudentClass} from "./callables/moveStudentClass";
export {resetPassword} from "./callables/resetPassword";
export {setTeacherClasses} from "./callables/setTeacherClasses";
export {setUserActive} from "./callables/setUserActive";
