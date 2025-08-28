import axios from 'axios';
import { config } from '../config';

interface GoogleBooksResponse {
  totalItems: number;
  items?: GoogleBookItem[];
}

interface GoogleBookItem {
  id: string;
  volumeInfo: {
    title: string;
    authors?: string[];
    publisher?: string;
    publishedDate?: string;
    description?: string;
    pageCount?: number;
    industryIdentifiers?: Array<{
      type: string;
      identifier: string;
    }>;
    imageLinks?: {
      thumbnail?: string;
      smallThumbnail?: string;
    };
  };
}

interface OpenBDBook {
  onix: {
    RecordReference?: string;
    ProductIdentifier?: {
      IDValue?: string;
    };
    DescriptiveDetail?: {
      TitleDetail?: {
        TitleElement?: Array<{
          TitleText?: string;
        }>;
      };
      Contributor?: Array<{
        PersonName?: string;
        ContributorRole?: string[];
      }>;
      Extent?: Array<{
        ExtentType?: string;
        ExtentValue?: string;
      }>;
    };
    CollateralDetail?: {
      TextContent?: Array<{
        Text?: string;
        TextType?: string;
      }>;
      SupportingResource?: Array<{
        ResourceContentType?: string;
        ResourceVersion?: Array<{
          ResourceLink?: string;
        }>;
      }>;
    };
    PublishingDetail?: {
      Imprint?: {
        ImprintName?: string;
      };
      PublishingDate?: Array<{
        Date?: string;
        DateFormat?: string;
      }>;
    };
  };
  summary: {
    isbn?: string;
    title?: string;
    author?: string;
    publisher?: string;
    pubdate?: string;
    cover?: string;
  };
}

export interface BookSearchResult {
  isbn?: string;
  title: string;
  author: string;
  publisher?: string;
  publishedDate?: string;
  pageCount?: number;
  description?: string;
  // Note: coverImageUrl is only used for external book search results.
  // When saving to database, iOS app should upload the image and use coverImageId instead.
  coverImageUrl?: string;
  dataSource: 'googleBooks' | 'openBD' | 'manual' | 'rakutenBooks';
  affiliateUrl?: string; // 楽天のアフィリエイトリンク用
}

interface RakutenBooksResponse {
  Items: RakutenBooksItem[];
  count: number;
  page: number;
  first: number;
  last: number;
  hits: number;
  carrier: number;
  pageCount: number;
}

interface RakutenBooksItem {
  Item: {
    title: string;
    author: string;
    publisherName: string;
    isbn: string;
    salesDate: string;
    itemCaption: string;
    largeImageUrl: string;
    affiliateUrl: string;
    itemUrl: string;
    size?: string;
  };
}

export class BookSearchService {
  private googleBooksApiKey: string;
  private rakutenApplicationId: string;
  private rakutenAffiliateId: string;

  constructor(googleBooksApiKey: string) {
    this.googleBooksApiKey = googleBooksApiKey;
    this.rakutenApplicationId = config.rakutenApplicationId;
    this.rakutenAffiliateId = config.rakutenAffiliateId;
  }

  async searchByISBN(isbn: string): Promise<BookSearchResult[]> {
    const normalizedISBN = isbn.replace(/-/g, '');
    const results: BookSearchResult[] = [];

    // 楽天ブックスAPI検索（優先）
    if (this.rakutenApplicationId) {
      try {
        const rakutenResults = await this.searchRakutenBooksByISBN(normalizedISBN);
        if (rakutenResults.length > 0) {
          results.push(...rakutenResults);
          return results; // 楽天で見つかったら即座に返す
        }
      } catch (error) {
        console.error('Rakuten Books search error:', error);
      }
    }

    // OpenBD API検索
    try {
      const openBDResult = await this.searchOpenBD(normalizedISBN);
      if (openBDResult) {
        results.push(openBDResult);
      }
    } catch (error) {
      console.error('OpenBD search error:', error);
    }

    // Google Books API検索（OpenBDで見つからない場合）
    if (results.length === 0) {
      try {
        const googleResult = await this.searchGoogleBooks(`isbn:${normalizedISBN}`);
        results.push(...googleResult);
      } catch (error) {
        console.error('Google Books search error:', error);
      }
    }

    return results;
  }

  async searchByQuery(query: string): Promise<BookSearchResult[]> {
    const results: BookSearchResult[] = [];

    // 楽天ブックスAPI検索（優先）
    if (this.rakutenApplicationId) {
      try {
        const rakutenResults = await this.searchRakutenBooksByKeyword(query);
        if (rakutenResults.length > 0) {
          results.push(...rakutenResults);
          return results; // 楽天で見つかったら即座に返す
        }
      } catch (error) {
        console.error('Rakuten Books search error:', error);
      }
    }

    // Google Books API検索
    try {
      const googleResults = await this.searchGoogleBooks(query);
      results.push(...googleResults);
    } catch (error) {
      console.error('Google Books search error:', error);
    }

    return results;
  }

  private async searchOpenBD(isbn: string): Promise<BookSearchResult | null> {
    const response = await axios.get<(OpenBDBook | null)[]>(
      `https://api.openbd.jp/v1/get?isbn=${isbn}`
    );

    if (!response.data || response.data.length === 0 || !response.data[0]) {
      return null;
    }

    const book = response.data[0];
    return this.parseOpenBDBook(book);
  }

  private async searchGoogleBooks(query: string): Promise<BookSearchResult[]> {
    const response = await axios.get<GoogleBooksResponse>(
      'https://www.googleapis.com/books/v1/volumes',
      {
        params: {
          q: query,
          key: this.googleBooksApiKey,
          maxResults: 20,
          printType: 'books',
        },
      }
    );

    if (!response.data.items || response.data.items.length === 0) {
      return [];
    }

    return response.data.items.map((item: GoogleBookItem) => this.parseGoogleBook(item));
  }

  private parseOpenBDBook(book: OpenBDBook): BookSearchResult {
    const summary = book.summary || {};
    const onix = book.onix || {};
    const descriptive = onix.DescriptiveDetail || {};
    const publishing = onix.PublishingDetail || {};
    const collateral = onix.CollateralDetail || {};

    // タイトル
    let title = summary.title || '';
    if (!title && descriptive.TitleDetail?.TitleElement?.[0]?.TitleText) {
      title = descriptive.TitleDetail.TitleElement[0].TitleText;
    }

    // 著者
    let author = summary.author || '';
    if (!author && descriptive.Contributor && descriptive.Contributor.length > 0) {
      author = descriptive.Contributor
        .filter((c) => c.PersonName)
        .map((c) => c.PersonName)
        .join(', ');
    }

    // 出版社
    let publisher = summary.publisher || '';
    if (!publisher && publishing.Imprint?.ImprintName) {
      publisher = publishing.Imprint.ImprintName;
    }

    // 出版日
    let publishedDate = summary.pubdate || '';
    if (!publishedDate && publishing.PublishingDate?.[0]?.Date) {
      const date = publishing.PublishingDate[0].Date;
      if (date.length === 8) {
        publishedDate = `${date.slice(0, 4)}-${date.slice(4, 6)}-${date.slice(6, 8)}`;
      }
    }

    // ページ数
    let pageCount: number | undefined;
    if (descriptive.Extent) {
      const pageExtent = descriptive.Extent.find((e) => e.ExtentType === '11');
      if (pageExtent?.ExtentValue) {
        pageCount = parseInt(pageExtent.ExtentValue, 10);
      }
    }

    // 説明
    let description = '';
    if (collateral.TextContent) {
      const descContent = collateral.TextContent.find((c) => c.TextType === '03');
      if (descContent?.Text) {
        description = descContent.Text;
      }
    }

    // カバー画像
    let coverImageUrl = summary.cover;
    if (!coverImageUrl && collateral.SupportingResource) {
      const coverResource = collateral.SupportingResource.find(
        (r) => r.ResourceContentType === '01'
      );
      if (coverResource?.ResourceVersion?.[0]?.ResourceLink) {
        coverImageUrl = coverResource.ResourceVersion[0].ResourceLink;
      }
    }

    return {
      isbn: summary.isbn || onix.ProductIdentifier?.IDValue,
      title: title || '不明なタイトル',
      author: author || '不明な著者',
      publisher: publisher || undefined,
      publishedDate: publishedDate || undefined,
      pageCount,
      description: description || undefined,
      coverImageUrl: coverImageUrl || undefined,
      dataSource: 'openBD',
    };
  }

  private parseGoogleBook(item: GoogleBookItem): BookSearchResult {
    const volumeInfo = item.volumeInfo;

    // ISBN取得
    let isbn: string | undefined;
    if (volumeInfo.industryIdentifiers) {
      const isbn13 = volumeInfo.industryIdentifiers.find((id) => id.type === 'ISBN_13');
      const isbn10 = volumeInfo.industryIdentifiers.find((id) => id.type === 'ISBN_10');
      isbn = isbn13?.identifier || isbn10?.identifier;
    }

    // カバー画像URL
    const coverImageUrl = volumeInfo.imageLinks?.thumbnail?.replace('http://', 'https://');

    return {
      isbn,
      title: volumeInfo.title,
      author: volumeInfo.authors?.join(', ') || '不明な著者',
      publisher: volumeInfo.publisher,
      publishedDate: volumeInfo.publishedDate,
      pageCount: volumeInfo.pageCount,
      description: volumeInfo.description,
      coverImageUrl,
      dataSource: 'googleBooks',
    };
  }

  private async searchRakutenBooksByISBN(isbn: string): Promise<BookSearchResult[]> {
    const params = new URLSearchParams({
      format: 'json',
      isbn: isbn,
      applicationId: this.rakutenApplicationId,
      hits: '20',
    });

    if (this.rakutenAffiliateId) {
      params.append('affiliateId', this.rakutenAffiliateId);
    }

    const response = await axios.get<RakutenBooksResponse>(
      `https://app.rakuten.co.jp/services/api/BooksBook/Search/20170404?${params.toString()}`
    );

    if (!response.data.Items || response.data.Items.length === 0) {
      return [];
    }

    return response.data.Items.map((item) => this.parseRakutenBook(item));
  }

  private async searchRakutenBooksByKeyword(keyword: string): Promise<BookSearchResult[]> {
    const params = new URLSearchParams({
      format: 'json',
      keyword: keyword,
      applicationId: this.rakutenApplicationId,
      hits: '20',
      booksGenreId: '001', // 本・雑誌・コミック
    });

    if (this.rakutenAffiliateId) {
      params.append('affiliateId', this.rakutenAffiliateId);
    }

    const response = await axios.get<RakutenBooksResponse>(
      `https://app.rakuten.co.jp/services/api/BooksTotal/Search/20170404?${params.toString()}`
    );

    if (!response.data.Items || response.data.Items.length === 0) {
      return [];
    }

    return response.data.Items.map((item) => this.parseRakutenBook(item));
  }

  private parseRakutenBook(item: RakutenBooksItem): BookSearchResult {
    const book = item.Item;

    // ページ数の抽出（サイズフィールドから）
    let pageCount: number | undefined;
    if (book.size) {
      const pageMatch = book.size.match(/(\d+)p/);
      if (pageMatch) {
        pageCount = parseInt(pageMatch[1], 10);
      }
    }

    // 出版日のフォーマット変換
    let publishedDate: string | undefined;
    if (book.salesDate) {
      // 楽天の日付形式は "2023年12月10日頃" のような形式
      const dateMatch = book.salesDate.match(/(\d{4})年(\d{1,2})月(\d{1,2})日/);
      if (dateMatch) {
        const year = dateMatch[1];
        const month = dateMatch[2].padStart(2, '0');
        const day = dateMatch[3].padStart(2, '0');
        publishedDate = `${year}-${month}-${day}`;
      }
    }

    return {
      isbn: book.isbn,
      title: book.title,
      author: book.author || '不明な著者',
      publisher: book.publisherName,
      publishedDate,
      pageCount,
      description: book.itemCaption,
      coverImageUrl: book.largeImageUrl,
      dataSource: 'rakutenBooks',
      affiliateUrl: book.affiliateUrl,
    };
  }
}
