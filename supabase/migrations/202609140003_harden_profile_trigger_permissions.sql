-- The function is used only by the auth.users trigger, never as a client RPC.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
