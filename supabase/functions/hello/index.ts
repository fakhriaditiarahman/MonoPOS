import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

export default {
  fetch: withSupabase({ auth: ["publishable", "secret"] }, async (req, ctx) => {
    const { data } = await ctx.supabase.from("todos").select();
    return Response.json(data);
  }),
};
