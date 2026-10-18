import {setGlobalOptions} from "firebase-functions/v2";

import {REGION} from "./config";

setGlobalOptions({region: REGION, maxInstances: 10});

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

export {onBookWritten} from "./triggers/onBookWritten";
export {onCommentCreated} from "./triggers/onCommentCreated";
export {onJournalWritten} from "./triggers/onJournalWritten";
export {onProgramWritten} from "./triggers/onProgramWritten";
export {onSchoolUpdated} from "./triggers/onSchoolChanges";
export {onTeacherWritten} from "./triggers/onTeacherWritten";
export {onUserUpdated} from "./triggers/onUserUpdated";
