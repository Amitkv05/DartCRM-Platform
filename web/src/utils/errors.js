export function getErrorMessage(error, fallback = "Something went wrong") {
  const message =
    error?.response?.data?.message ||
    error?.response?.data?.error ||
    error?.message ||
    fallback;
  const requestId = error?.response?.data?.requestId;
  return requestId ? `${message} (Request ID: ${requestId})` : message;
}
