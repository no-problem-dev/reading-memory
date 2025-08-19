import Anthropic from '@anthropic-ai/sdk';

export class ClaudeService {
  private client: Anthropic;
  
  constructor() {
    // Secret Managerから取得する前提
    const apiKey = process.env.CLAUDE_API_KEY;
    if (!apiKey) {
      throw new Error('CLAUDE_API_KEY is not set');
    }
    
    this.client = new Anthropic({
      apiKey: apiKey,
    });
  }
  
  /**
   * 本に関する質問に答える
   */
  async generateBookChatResponse(
    bookTitle: string,
    bookAuthor: string,
    previousChats: Array<{ message: string; isAI: boolean }>,
    userMessage: string
  ): Promise<string> {
    try {
      // 会話履歴を構築
      const conversationHistory = previousChats
        .slice(-10) // 最新10件まで
        .map(chat => ({
          role: chat.isAI ? 'assistant' as const : 'user' as const,
          content: chat.message
        }));
      
      const systemPrompt = `あなたは読書アシスタントです。ユーザーが「${bookTitle}」（著者: ${bookAuthor}）について質問や感想を共有しています。
      
以下の点に注意して応答してください：
- 簡潔で親しみやすい日本語で返答する
- 本の内容について深い洞察を提供する
- ユーザーの感想や気づきに共感的に応答する
- 新しい視点や関連する話題を提案する
- 長すぎない返答を心がける（最大3-4文程度）`;

      const response = await this.client.messages.create({
        model: 'claude-sonnet-4-0',
        max_tokens: 300,
        temperature: 0.7,
        system: systemPrompt,
        messages: [
          ...conversationHistory,
          { role: 'user', content: userMessage }
        ]
      });
      
      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Unexpected response type');
      }
      
      return content.text;
    } catch (error) {
      console.error('Claude API error:', error);
      throw new Error('AI応答の生成に失敗しました');
    }
  }
  
  /**
   * 読書メモの要約を生成
   */
  async generateBookSummary(
    bookTitle: string,
    bookAuthor: string,
    chats: Array<{ message: string; isAI: boolean }>
  ): Promise<string> {
    try {
      // ユーザーのメッセージのみを抽出
      const userMessages = chats
        .filter(chat => !chat.isAI)
        .map(chat => chat.message)
        .join('\n\n');
      
      if (!userMessages) {
        return '読書メモがありません。';
      }
      
      const systemPrompt = `あなたは読書ノートをまとめる専門家です。`;
      
      const userPrompt = `以下は「${bookTitle}」（著者: ${bookAuthor}）についての読書メモです。
これらのメモから、ユーザーが得た主要な気づきや感想を3-5個の箇条書きでまとめてください。

読書メモ:
${userMessages}`;

      const response = await this.client.messages.create({
        model: 'claude-sonnet-4-0',
        max_tokens: 500,
        temperature: 0.3,
        system: systemPrompt,
        messages: [
          { role: 'user', content: userPrompt }
        ]
      });
      
      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Unexpected response type');
      }
      
      return content.text;
    } catch (error) {
      console.error('Claude API error:', error);
      throw new Error('要約の生成に失敗しました');
    }
  }
}