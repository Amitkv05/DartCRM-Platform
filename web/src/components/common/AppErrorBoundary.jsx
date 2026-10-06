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
      <div className="crm-auth-shell grid min-h-screen place-items-center p-6">
        <div className="crm-auth-panel w-full max-w-lg rounded-[20px] p-8 text-center">
          <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl border border-red-400/15 bg-red-400/[.07] text-red-300"><AlertTriangle size={24}/></div>
          <h1 className="mt-5 text-[18px] font-black text-white">This screen hit an unexpected error</h1>
          <p className="mt-2 text-[10px] leading-5 text-slate-500">The CRM session is still safe. Reload the page and, if it happens again, send the browser console error with the screen name.</p>
          <pre className="mt-4 max-h-32 overflow-auto rounded-xl border border-white/[.07] bg-black/20 p-3 text-left text-[9px] text-slate-400">{String(this.state.error?.message || this.state.error)}</pre>
          <Button className="mt-5" variant="primary" onClick={() => window.location.reload()}><RotateCcw size={15}/>Reload CRM</Button>
        </div>
      </div>
    );
  }
}
