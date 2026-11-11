/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_MEDIA_BASE_URL: string;
  readonly VITE_CLOUDINARY_FOLDER?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
