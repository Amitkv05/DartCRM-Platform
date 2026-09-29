import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
export default function NotFoundPage(){return <div className="grid min-h-[60vh] place-items-center text-center"><div><p className="text-7xl font-black text-slate-200 dark:text-slate-800">404</p><h1 className="mt-2 text-2xl font-black">Page not found</h1><p className="mt-2 text-sm text-slate-500">The requested CRM screen does not exist.</p><Button asChild variant="primary" className="mt-5"><Link to="/dashboard">Back to Dashboard</Link></Button></div></div>}
