import { supabase } from "@/integrations/supabase/client";

interface SendEmailParams {
  to: string;
  subject: string;
  html: string;
  from?: string;
}

export const sendEmail = async ({ to, subject, html, from }: SendEmailParams) => {
  try {
    const { data, error } = await supabase.functions.invoke('send-email', {
      body: {
        to,
        subject,
        html,
        from,
      },
    });

    if (error) throw error;
    return { success: true, data };
  } catch (error) {
    console.error('Error sending email:', error);
    return { success: false, error };
  }
};

export const sendWelcomeEmail = async (email: string, fullName: string) => {
  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
          .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 20px; color: #6b7280; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Bem-vindo ao Facilities Hub! 🎉</h1>
          </div>
          <div class="content">
            <h2>Olá, ${fullName}!</h2>
            <p>Estamos muito felizes em ter você conosco no <strong>Facilities Hub</strong>, sua plataforma completa de gestão de facilities.</p>
            
            <p>Com o Facilities Hub você poderá:</p>
            <ul>
              <li>Gerenciar ordens de serviço e manutenções</li>
              <li>Controlar ativos e equipamentos</li>
              <li>Acompanhar indicadores e relatórios</li>
              <li>Otimizar processos de facilities</li>
            </ul>
            
            <p>Sua conta foi criada com sucesso e você já pode começar a explorar a plataforma.</p>
            
            <a href="${window.location.origin}/dashboard" class="button">Acessar Dashboard</a>
            
            <p>Se você tiver alguma dúvida ou precisar de ajuda, nossa equipe está sempre disponível.</p>
            
            <p>Atenciosamente,<br><strong>Equipe Facilities Hub</strong></p>
          </div>
          <div class="footer">
            <p>Este é um email automático, por favor não responda.</p>
          </div>
        </div>
      </body>
    </html>
  `;

  return sendEmail({
    to: email,
    subject: 'Bem-vindo ao Facilities Hub!',
    html,
  });
};

export const sendPasswordResetEmail = async (email: string, resetLink: string) => {
  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #dc2626; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
          .button { display: inline-block; background: #dc2626; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 20px; color: #6b7280; font-size: 14px; }
          .warning { background: #fef3c7; padding: 15px; border-left: 4px solid #f59e0b; margin: 20px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Redefinição de Senha 🔐</h1>
          </div>
          <div class="content">
            <h2>Olá!</h2>
            <p>Recebemos uma solicitação para redefinir a senha da sua conta no Facilities Hub.</p>
            
            <p>Clique no botão abaixo para criar uma nova senha:</p>
            
            <a href="${resetLink}" class="button">Redefinir Senha</a>
            
            <div class="warning">
              <strong>⚠️ Importante:</strong> Este link expira em 1 hora e só pode ser usado uma vez.
            </div>
            
            <p>Se você não solicitou a redefinição de senha, ignore este email. Sua conta permanecerá segura.</p>
            
            <p>Atenciosamente,<br><strong>Equipe Facilities Hub</strong></p>
          </div>
          <div class="footer">
            <p>Este é um email automático, por favor não responda.</p>
          </div>
        </div>
      </body>
    </html>
  `;

  return sendEmail({
    to: email,
    subject: 'Redefinição de Senha - Facilities Hub',
    html,
  });
};
