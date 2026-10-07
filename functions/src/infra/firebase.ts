import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

if (getApps().length === 0) initializeApp();

export const db = getFirestore();
export const auth = getAuth();
export const messaging = getMessaging();

export const schoolRef = (schoolId: string) => db.doc(`schools/${schoolId}`);
export const usersCol = (schoolId: string) => schoolRef(schoolId).collection("users");
export const classesCol = (schoolId: string) => schoolRef(schoolId).collection("classes");
export const statsCol = (schoolId: string) => schoolRef(schoolId).collection("studentStats");
export const programsCol = (schoolId: string) => schoolRef(schoolId).collection("programs");
export const activeProgramsCol = (schoolId: string) =>
  schoolRef(schoolId).collection("activePrograms");
export const auditCol = (schoolId: string) => schoolRef(schoolId).collection("auditLogs");
