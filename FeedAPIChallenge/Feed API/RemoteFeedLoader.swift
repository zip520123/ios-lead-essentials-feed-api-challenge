//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url, completion: { [weak self] result in
			guard self != nil else { return }
			switch result {
			case let .success((data, response)):
				completion(FeedLoaderResultMapper.map(data, response))
			case .failure:
				completion(.failure(RemoteFeedLoader.Error.connectivity))
			}
		})
	}
}

private struct FeedLoaderResultMapper {
	static func map(_ data: Data, _ response: HTTPURLResponse) -> FeedLoader.Result {
		if response.statusCode == 200, let root = try? JSONDecoder().decode(RemoteFeedLoadImagesRoot.self, from: data) {
			return .success(root.images)
		} else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}
	}

	static func map(_ result: HTTPClient.Result) -> FeedLoader.Result {
		switch result {
		case let .success((data, response)):
			if response.statusCode == 200, let root = try? JSONDecoder().decode(RemoteFeedLoadImagesRoot.self, from: data) {
				return .success(root.images)
			} else {
				return .failure(RemoteFeedLoader.Error.invalidData)
			}
		case .failure:
			return .failure(RemoteFeedLoader.Error.connectivity)
		}
	}

	private struct RemoteFeedLoadImagesRoot: Decodable {
		let items: [RemoteFeedLoadImage]
		var images: [FeedImage] {
			items.map { $0.feedImage }
		}
	}

	private struct RemoteFeedLoadImage: Decodable {
		let id: UUID
		let desc: String?
		let location: String?
		let url: URL

		enum CodingKeys: String, CodingKey {
			case id = "image_id"
			case desc = "image_desc"
			case location = "image_loc"
			case url = "image_url"
		}

		var feedImage: FeedImage {
			FeedImage(id: id, description: desc, location: location, url: url)
		}
	}
}
