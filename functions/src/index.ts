import {setGlobalOptions} from "firebase-functions/v2";

import {REGION} from "./config";

// Every instance takes 1 vCPU from Cloud Run's "Total CPU allocation" quota,
// 20 vCPU per region by default and shared by all functions. Five instances
// of 80 concurrent requests each are far above what one function needs, and
// keep a busy function from taking the whole quota.
setGlobalOptions({region: REGION, maxInstances: 5});

export {acceptTerms} from "./callables/acceptTerms";
export {addStudents} from "./callables/addStudents";
export {addTeacher} from "./callables/addTeacher";
export {claimAccount} from "./callables/claimAccount";
export {deleteBook} from "./callables/deleteBook";
export {deleteMyAccount} from "./callables/deleteMyAccount";
export {eraseStudent} from "./callables/eraseStudent";
export {removeStudent} from "./callables/removeStudent";
export {removeTeacher} from "./callables/removeTeacher";
export {reportContent} from "./callables/reportContent";
export {resolveReport} from "./callables/resolveReport";
export {restoreBook} from "./callables/restoreBook";
export {reviewSuggestion} from "./callables/reviewSuggestion";
export {saveBook} from "./callables/saveBook";
export {setBookCover} from "./callables/setBookCover";

export {dailyRefresh} from "./scheduled/dailyRefresh";
export {teacherDigest} from "./scheduled/teacherDigest";

export {onBookWritten} from "./triggers/onBookWritten";
export {onCommentCreated} from "./triggers/onCommentCreated";
export {onJournalWritten} from "./triggers/onJournalWritten";
export {onProgramWritten} from "./triggers/onProgramWritten";
export {onSchoolUpdated} from "./triggers/onSchoolChanges";
export {onTeacherWritten} from "./triggers/onTeacherWritten";
export {onUserUpdated} from "./triggers/onUserUpdated";
