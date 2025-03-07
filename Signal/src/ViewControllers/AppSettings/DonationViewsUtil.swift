//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import Foundation
import Lottie
import UIKit

public class ProfileBadgeLookup {
    let boostBadge: ProfileBadge?
    let badgesBySubscriptionLevel: [UInt: ProfileBadge]

    public convenience init() {
        self.init(boostBadge: nil, subscriptionLevels: [])
    }

    public init(boostBadge: ProfileBadge?, subscriptionLevels: [SubscriptionLevel]) {
        self.boostBadge = boostBadge

        var badgesBySubscriptionLevel = [UInt: ProfileBadge]()
        for subscriptionLevel in subscriptionLevels {
            badgesBySubscriptionLevel[subscriptionLevel.level] = subscriptionLevel.badge
        }
        self.badgesBySubscriptionLevel = badgesBySubscriptionLevel
    }

    private func get(donationReceipt: DonationReceipt) -> ProfileBadge? {
        if let subscriptionLevel = donationReceipt.subscriptionLevel {
            return badgesBySubscriptionLevel[subscriptionLevel]
        } else {
            return boostBadge
        }
    }

    public func getImage(donationReceipt: DonationReceipt, preferDarkTheme: Bool) -> UIImage? {
        guard let assets = get(donationReceipt: donationReceipt)?.assets else { return nil }
        return preferDarkTheme ? assets.dark16 : assets.light16
    }

    public func attemptToPopulateBadgeAssets(populateAssetsOnBadge: (ProfileBadge) -> Promise<Void>) -> Guarantee<Void> {
        var badgesToLoad = Array(badgesBySubscriptionLevel.values)
        if let boostBadge = boostBadge { badgesToLoad.append(boostBadge) }

        let promises = badgesToLoad.map { populateAssetsOnBadge($0) }
        return Promise.when(fulfilled: promises).recover { _ in Guarantee.value(()) }
    }
}

public class SubscriptionReadMoreSheet: InteractiveSheetViewController {
    let contentScrollView = UIScrollView()
    let stackView = UIStackView()
    public override var interactiveScrollViews: [UIScrollView] { [contentScrollView] }
    public override var minHeight: CGFloat { min(740, CurrentAppContext().frame.height - (view.safeAreaInsets.top + 32)) }
    override var maximizedHeight: CGFloat { minHeight }
    override var sheetBackgroundColor: UIColor { Theme.tableView2PresentedBackgroundColor }

    // MARK: -

    override public func viewDidLoad() {
        super.viewDidLoad()

        contentView.addSubview(contentScrollView)

        stackView.axis = .vertical
        stackView.layoutMargins = UIEdgeInsets(hMargin: 24, vMargin: 24)
        stackView.isLayoutMarginsRelativeArrangement = true
        contentScrollView.addSubview(stackView)
        stackView.autoPinHeightToSuperview()
        // Pin to the scroll view's viewport, not to its scrollable area
        stackView.autoPinWidth(toWidthOf: contentScrollView)

        contentScrollView.autoPinEdgesToSuperviewEdges()
        contentScrollView.alwaysBounceVertical = true

        buildContents()
    }

    private func buildContents() {

        // Header image
        let image = UIImage(named: "sustainer-heart")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        stackView.addArrangedSubview(imageView)
        stackView.setCustomSpacing(12, after: imageView)

        // Header label
        let titleLabel = UILabel()
        titleLabel.textAlignment = .natural
        titleLabel.font = UIFont.ows_dynamicTypeTitle2.ows_semibold
        titleLabel.text = NSLocalizedString(
            "SUSTAINER_READ_MORE_TITLE",
            comment: "Title for the signal sustainer read more view"
        )
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(12, after: titleLabel)

        let firstDescriptionBlock = UILabel()
        firstDescriptionBlock.textAlignment = .natural
        firstDescriptionBlock.font = .ows_dynamicTypeBody
        firstDescriptionBlock.text = NSLocalizedString(
            "SUSTAINER_READ_MORE_DESCRIPTION_BLOCK_ONE",
            comment: "First block of description text in read more sheet"
        )
        firstDescriptionBlock.numberOfLines = 0
        firstDescriptionBlock.lineBreakMode = .byWordWrapping
        stackView.addArrangedSubview(firstDescriptionBlock)
        stackView.setCustomSpacing(32, after: firstDescriptionBlock)

        let titleLabel2 = UILabel()
        titleLabel2.textAlignment = .natural
        titleLabel2.font = UIFont.ows_dynamicTypeTitle2.ows_semibold
        titleLabel2.text = NSLocalizedString(
            "SUSTAINER_READ_MORE_WHY_CONTRIBUTE",
            comment: "Why Contribute title for the signal sustainer read more view"
        )
        titleLabel2.numberOfLines = 0
        titleLabel2.lineBreakMode = .byWordWrapping
        stackView.addArrangedSubview(titleLabel2)
        stackView.setCustomSpacing(12, after: titleLabel2)

        let secondDescriptionBlock = UILabel()
        secondDescriptionBlock.textAlignment = .natural
        secondDescriptionBlock.font = .ows_dynamicTypeBody
        secondDescriptionBlock.text = NSLocalizedString(
            "SUSTAINER_READ_MORE_DESCRIPTION_BLOCK_TWO",
            comment: "Second block of description text in read more sheet"
        )
        secondDescriptionBlock.numberOfLines = 0
        secondDescriptionBlock.lineBreakMode = .byWordWrapping
        stackView.addArrangedSubview(secondDescriptionBlock)
    }
}

public final class DonationViewsUtil {
    public static func loadSubscriptionLevels(badgeStore: BadgeStore) -> Promise<[SubscriptionLevel]> {
        firstly {
            SubscriptionManager.getSubscriptions()
        }.then { (fetchedSubscriptions: [SubscriptionLevel]) -> Promise<[SubscriptionLevel]> in
            let badgeUpdatePromises = fetchedSubscriptions.map { badgeStore.populateAssetsOnBadge($0.badge) }
            return Promise.when(fulfilled: badgeUpdatePromises).map { fetchedSubscriptions }
        }
    }

    public static func loadCurrentSubscription(subscriberID: Data?) -> Promise<Subscription?> {
        if let subscriberID = subscriberID {
            return SubscriptionManager.getCurrentSubscriptionStatus(for: subscriberID)
        } else {
            return Promise.value(nil)
        }
    }

    public static func subscriptionLevelForSubscription(subscriptionLevels: [SubscriptionLevel],
                                                        subscription: Subscription) -> SubscriptionLevel? {
        subscriptionLevels.first { $0.level == subscription.level }
    }

    public static func getMySupportCurrentSubscriptionTableItem(subscriptionLevel: SubscriptionLevel?,
                                                                currentSubscription: Subscription,
                                                                subscriptionRedemptionFailureReason: SubscriptionRedemptionFailureReason,
                                                                statusLabelToModify: LinkingTextView) -> OWSTableItem {
        OWSTableItem.init(customCellBlock: {
            let isPending = isSubscriptionRedemptionPending()
            let didFail = subscriptionRedemptionFailureReason != .none
            if subscriptionLevel == nil {
                owsFailDebug("A subscription level should be provided. We'll do our best without one")
            }

            let cell = OWSTableItem.newCell()

            let hStackView = UIStackView()
            cell.contentView.addSubview(hStackView)
            hStackView.axis = .horizontal
            hStackView.spacing = 12
            hStackView.alignment = .center
            hStackView.autoPinEdgesToSuperviewMargins()

            let badgeImage = subscriptionLevel?.badge.assets?.universal160
            let badgeImageView: UIImageView = UIImageView(image: badgeImage)
            hStackView.addArrangedSubview(badgeImageView)
            badgeImageView.autoSetDimensions(to: CGSize(square: 64))
            badgeImageView.alpha = isPending || didFail ? 0.5 : 1

            if isPending {
                let redemptionLoadingSpinner = AnimationView(name: "indeterminate_spinner_blue")
                hStackView.addSubview(redemptionLoadingSpinner)
                redemptionLoadingSpinner.loopMode = .loop
                redemptionLoadingSpinner.contentMode = .scaleAspectFit
                redemptionLoadingSpinner.autoPin(toEdgesOf: badgeImageView, with: UIEdgeInsets(hMargin: 14, vMargin: 14))
                redemptionLoadingSpinner.play()
            }

            let vStackView: UIView = {
                let titleLabel: UILabel = {
                    let titleLabel = UILabel()
                    titleLabel.text = subscriptionLevel?.name
                    titleLabel.textColor = Theme.primaryTextColor
                    titleLabel.font = .ows_dynamicTypeBody.ows_semibold
                    titleLabel.numberOfLines = 3
                    return titleLabel
                }()

                let pricingLabel: UILabel = {
                    let pricingLabel = UILabel()
                    let pricingFormat = NSLocalizedString("SUSTAINER_VIEW_PRICING", comment: "Pricing text for sustainer view badges, embeds {{price}}")
                    var amount = currentSubscription.amount
                    if !Stripe.zeroDecimalCurrencyCodes.contains(currentSubscription.currency) {
                        amount = amount.dividing(by: NSDecimalNumber(value: 100))
                    }
                    let currencyString = DonationUtilities.formatCurrency(amount, currencyCode: currentSubscription.currency)
                    pricingLabel.text = String(format: pricingFormat, currencyString)
                    pricingLabel.textColor = Theme.primaryTextColor
                    pricingLabel.font = .ows_dynamicTypeBody2
                    pricingLabel.numberOfLines = 3
                    return pricingLabel
                }()

                let statusText: NSMutableAttributedString
                if isPending {
                    let text = NSLocalizedString("SUSTAINER_VIEW_PROCESSING_TRANSACTION", comment: "Status text while processing a badge redemption")
                    statusText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: Theme.secondaryTextAndIconColor, .font: UIFont.ows_dynamicTypeBody2])
                } else if didFail {
                    let helpFormat = subscriptionRedemptionFailureReason == .paymentFailed ? NSLocalizedString("SUSTAINER_VIEW_PAYMENT_ERROR", comment: "Payment error occurred text, embeds {{link to contact support}}")
                    : NSLocalizedString("SUSTAINER_VIEW_CANT_ADD_BADGE", comment: "Couldn't add badge text, embeds {{link to contact support}}")
                    let contactSupport = NSLocalizedString("SUSTAINER_VIEW_CONTACT_SUPPORT", comment: "Contact support link")
                    let text = String(format: helpFormat, contactSupport)
                    let attributedText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: Theme.secondaryTextAndIconColor, .font: UIFont.ows_dynamicTypeBody2])
                    attributedText.addAttributes([.link: NSURL()], range: NSRange(location: text.utf16.count - contactSupport.utf16.count, length: contactSupport.utf16.count))
                    statusText = attributedText
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    let renewalFormat = NSLocalizedString("SUSTAINER_VIEW_RENEWAL", comment: "Renewal date text for sustainer view level, embeds {{renewal date}}")
                    let renewalDate = Date(timeIntervalSince1970: currentSubscription.endOfCurrentPeriod)
                    let renewalString = dateFormatter.string(from: renewalDate)
                    let text = String(format: renewalFormat, renewalString)
                    statusText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: Theme.secondaryTextAndIconColor, .font: UIFont.ows_dynamicTypeBody2])
                }

                statusLabelToModify.attributedText = statusText
                statusLabelToModify.linkTextAttributes = [
                    .foregroundColor: Theme.accentBlueColor,
                    .underlineColor: UIColor.clear,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]

                let view = UIStackView(arrangedSubviews: [titleLabel,
                                                          pricingLabel,
                                                          statusLabelToModify])
                view.axis = .vertical
                view.distribution = .equalCentering
                view.spacing = 4

                return view
            }()
            hStackView.addArrangedSubview(vStackView)

            return cell
        })
    }

    private static func isSubscriptionRedemptionPending() -> Bool {
        var hasPendingJobs: Bool = SDSDatabaseStorage.shared.read { transaction in
            SubscriptionManager.subscriptionJobQueue.hasPendingJobs(transaction: transaction)
        }
        hasPendingJobs = hasPendingJobs || SubscriptionManager.subscriptionJobQueue.runningOperations.get().count != 0
        return hasPendingJobs
    }

    public static func getSubscriptionRedemptionFailureReason(subscription: Subscription?) -> SubscriptionRedemptionFailureReason {
        if let subscription = subscription,
           (subscription.status == .incomplete || subscription.status == .incompleteExpired) {
            return .paymentFailed
        }

        return SDSDatabaseStorage.shared.read { transaction in
            SubscriptionManager.lastReceiptRedemptionFailed(transaction: transaction)
        }
    }

    public static func openDonateWebsite() {
        UIApplication.shared.open(TSConstants.donateUrl, options: [:], completionHandler: nil)
    }

    public static func presentBadgeCantBeAddedSheet(viewController: UIViewController,
                                                    currentSubscription: Subscription?) {
        let failureReason = getSubscriptionRedemptionFailureReason(subscription: currentSubscription)

        let title = failureReason == .paymentFailed ? NSLocalizedString("SUSTAINER_VIEW_ERROR_PROCESSING_PAYMENT_TITLE", comment: "Action sheet title for Error Processing Payment sheet") : NSLocalizedString("SUSTAINER_VIEW_CANT_ADD_BADGE_TITLE", comment: "Action sheet title for Couldn't Add Badge sheet")
        let message = NSLocalizedString("SUSTAINER_VIEW_CANT_ADD_BADGE_MESSAGE", comment: "Action sheet message for Couldn't Add Badge sheet")

        let actionSheet = ActionSheetController(title: title, message: message)
        actionSheet.addAction(ActionSheetAction(
            title: NSLocalizedString("CONTACT_SUPPORT", comment: "Button text to initiate an email to signal support staff"),
            style: .default,
            handler: { _ in
                let localizedSheetTitle = NSLocalizedString("EMAIL_SIGNAL_TITLE",
                                                            comment: "Title for the fallback support sheet if user cannot send email")
                let localizedSheetMessage = NSLocalizedString("EMAIL_SIGNAL_MESSAGE",
                                                              comment: "Description for the fallback support sheet if user cannot send email")
                guard ComposeSupportEmailOperation.canSendEmails else {
                    let fallbackSheet = ActionSheetController(title: localizedSheetTitle,
                                                              message: localizedSheetMessage)
                    let buttonTitle = NSLocalizedString("BUTTON_OKAY", comment: "Label for the 'okay' button.")
                    fallbackSheet.addAction(ActionSheetAction(title: buttonTitle, style: .default))
                    viewController.presentActionSheet(fallbackSheet)
                    return
                }
                let supportVC = ContactSupportViewController()
                supportVC.selectedFilter = .donationsAndBadges
                let navVC = OWSNavigationController(rootViewController: supportVC)
                viewController.presentFormSheet(navVC, animated: true)
            }
        ))

        actionSheet.addAction(ActionSheetAction(
            title: NSLocalizedString("SUSTAINER_VIEW_SUBSCRIPTION_CONFIRMATION_NOT_NOW", comment: "Sustainer view Not Now Action sheet button"),
            style: .cancel,
            handler: nil
        ))
        viewController.navigationController?.topViewController?.presentActionSheet(actionSheet)
    }
}
