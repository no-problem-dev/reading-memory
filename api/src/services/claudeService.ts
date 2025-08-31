import Anthropic from '@anthropic-ai/sdk';

export class ClaudeService {
  private client: Anthropic;

  constructor() {
    // Secret Managerから取得する前提
    const apiKey = process.env.CLAUDE_API_KEY;
    if (!apiKey) {
      throw new Error('CLAUDE_API_KEY is not set');
    }

    // APIキーから改行文字を除去
    const cleanApiKey = apiKey.trim().replace(/[\r\n]/g, '');

    this.client = new Anthropic({
      apiKey: cleanApiKey,
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
        .map((chat) => ({
          role: chat.isAI ? 'assistant' as const : 'user' as const,
          content: chat.message,
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
          {role: 'user', content: userMessage},
        ],
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
      // 対話の全体を構築（ユーザーとAIの対話を含む）
      const conversation = chats
        .map((chat) => {
          const role = chat.isAI ? 'AI' : 'あなた';
          return `${role}: ${chat.message}`;
        })
        .join('\n\n');

      if (!conversation || chats.length === 0) {
        return 'まだ読書メモがありません。本について感じたことや気づいたことをチャットで記録してください。';
      }

      const systemPrompt = `あなたは優れた読書アドバイザーです。読者の読書体験を深く理解し、洞察に富んだ要約を作成します。
読者が本から得た価値を明確に言語化し、今後の人生や仕事に活かせる形で整理します。`;

      const userPrompt = `「${bookTitle}」（著者: ${bookAuthor}）についての読書記録を分析し、以下の形式で要約を作成してください。

【読書対話の記録】
${conversation}

【要約の形式】
1. 📚 この本から得た最も重要な学び（2-3個）
   - 具体的で実践可能な内容を箇条書きで

2. 💡 心に残った洞察や気づき（2-3個）
   - 読者の感情や思考の変化を含めて

3. 🎯 今後の行動への示唆（1-2個）
   - この本の学びをどう活かせるか

4. 📝 読者の成長ポイント
   - この読書体験を通じて読者がどう成長したか

注意事項：
- 読者の言葉や感情を大切にする
- 単なる内容の要約ではなく、読者の体験と学びに焦点を当てる
- 具体的で記憶に残る表現を使う
- 読者が後で見返したときに、読書体験を鮮明に思い出せるようにする`;

      const response = await this.client.messages.create({
        model: 'claude-sonnet-4-0',
        max_tokens: 1000,
        temperature: 0.7,
        system: systemPrompt,
        messages: [
          {role: 'user', content: userPrompt},
        ],
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
