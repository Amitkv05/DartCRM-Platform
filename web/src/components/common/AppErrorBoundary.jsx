import React from "react";
import { AlertTriangle, RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/button";

export default class AppErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    console.error("DartCRM UI error", error, info);
  }

  render() {
    if (!this.state.error) return this.props.children;
    return (
      <div className="grid min-h-screen place-items-center bg-slate-50 p-6 dark:bg-slate-950">
        <div className="w-full max-w-lg rounded-3xl border border-red-200 bg-white p-8 text-center shadow-soft dark:border-red-900/50 dark:bg-slate-900">
          <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-red-50 text-red-600 dark:bg-red-950/40"><AlertTriangle size={26}/></div>
          <h1 className="mt-5 text-xl font-black">This screen hit an unexpected error</h1>
          <p className="mt-2 text-sm text-slate-500">The CRM session is still safe. Reload the page and, if it happens again, send the browser console error with the screen name.</p>
          <pre className="mt-4 max-h-32 overflow-auto rounded-xl bg-slate-100 p-3 text-left text-xs text-slate-600 dark:bg-slate-950 dark:text-slate-300">{String(this.state.error?.message || this.state.error)}</pre>
          <Button className="mt-5" variant="primary" onClick={() => window.location.reload()}><RotateCcw size={16}/>Reload CRM</Button>
        </div>
      </div>
    );
  }
}
