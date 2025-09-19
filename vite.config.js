import { defineConfig } from 'vite'

export default defineConfig({
  server: {
    port: 5173,
    host: '0.0.0.0'
  },
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: {
        main: 'index.html',
        login: 'login.html',
        signup: 'signup.html',
        'student-panel': 'student-panel.html',
        'coach-admin-panel': 'coach-admin-panel.html',
        'video-upload': 'video-upload.html',
        'course-detail': 'course-detail.html',
        'create-course-step1': 'create-course-step1.html',
        'create-course-step2': 'create-course-step2.html',
        'create-course-step3': 'create-course-step3.html'
      }
    }
  },
  define: {
    global: 'globalThis'
  }
})