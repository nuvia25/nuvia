@extends('panel.layout.app')
@section('title', __('Subscription Payment'))
@section('titlebar_actions', '')

@section('additional_css')
    <style>
        #payment-form {
            width: 100%;
            /* min-width: 500px; */
            align-self: center;
            box-shadow: 0px 0px 0px 0.5px rgba(50, 50, 93, 0.1),
                0px 2px 5px 0px rgba(50, 50, 93, 0.1), 0px 1px 1.5px 0px rgba(0, 0, 0, 0.07);
            border-radius: 7px;
            padding: 40px;
        }

        .hidden {
            display: none;
        }

        #payment-message {
            color: rgb(105, 115, 134);
            font-size: 16px;
            line-height: 20px;
            padding-top: 12px;
            text-align: center;
        }

        #payment-element {
            margin-bottom: 24px;
        }

        /* Buttons and links */
        button {
            background: #5469d4;
            font-family: Arial, sans-serif;
            color: #ffffff;
            border-radius: 4px;
            border: 0;
            padding: 12px 16px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            display: block;
            transition: all 0.2s ease;
            box-shadow: 0px 4px 5.5px 0px rgba(0, 0, 0, 0.07);
            width: 100%;
        }

        button:hover {
            filter: contrast(115%);
        }

        button:disabled {
            opacity: 0.5;
            cursor: default;
        }

        /* spinner/processing state, errors */
        .spinner,
        .spinner:before,
        .spinner:after {
            border-radius: 50%;
        }

        .spinner {
            color: #ffffff;
            font-size: 22px;
            text-indent: -99999px;
            margin: 0px auto;
            position: relative;
            width: 20px;
            height: 20px;
            box-shadow: inset 0 0 0 2px;
            -webkit-transform: translateZ(0);
            -ms-transform: translateZ(0);
            transform: translateZ(0);
        }

        .spinner:before,
        .spinner:after {
            position: absolute;
            content: "";
        }

        .spinner:before {
            width: 10.4px;
            height: 20.4px;
            background: #5469d4;
            border-radius: 20.4px 0 0 20.4px;
            top: -0.2px;
            left: -0.2px;
            -webkit-transform-origin: 10.4px 10.2px;
            transform-origin: 10.4px 10.2px;
            -webkit-animation: loading 2s infinite ease 1.5s;
            animation: loading 2s infinite ease 1.5s;
        }

        .spinner:after {
            width: 10.4px;
            height: 10.2px;
            background: #5469d4;
            border-radius: 0 10.2px 10.2px 0;
            top: -0.1px;
            left: 10.2px;
            -webkit-transform-origin: 0px 10.2px;
            transform-origin: 0px 10.2px;
            -webkit-animation: loading 2s infinite ease;
            animation: loading 2s infinite ease;
        }

        @-webkit-keyframes loading {
            0% {
                -webkit-transform: rotate(0deg);
                transform: rotate(0deg);
            }

            100% {
                -webkit-transform: rotate(360deg);
                transform: rotate(360deg);
            }
        }

        @keyframes loading {
            0% {
                -webkit-transform: rotate(0deg);
                transform: rotate(0deg);
            }

            100% {
                -webkit-transform: rotate(360deg);
                transform: rotate(360deg);
            }
        }

        @media only screen and (max-width: 600px) {
            form {
                width: 80vw;
                min-width: initial;
            }
        }
    </style>
@endsection

@section('content')
    <!-- Page body -->
    <div class="py-10">
        <div class="container-xl">
            <div class="row row-cards">
                <div class="col-sm-8 col-lg-8">
                    @include('panel.user.finance.coupon.index')
                    <form
                        id="payment-form"
                        action="{{ route('dashboard.user.payment.subscription.checkout', ['gateway' => 'stripe']) }}"
                        method="post"
                    >
                        @csrf
                        {{-- <input type="hidden" name="planID" value="{{ $plan->id }}">
                        <input type="hidden" name="couponID" id="coupon">
                        <input type="hidden" name="orderID" value="{{$order_id}}">
                        <input type="hidden" name="payment_method" class="payment-method">
                        <input type="hidden" name="gateway" value="stripe"> --}}
                        <div class="row">
                            <div class="col-md-12 col-xl-12">
                                <div id="payment-element">
                                    <!--Stripe.js injects the Payment Element-->
                                </div>
                                <x-button
                                    class="w-full flex-wrap"
                                    id="submit"
                                    size="lg"
                                    type="{{ $app_is_demo ? 'button' : 'submit' }}"
                                    onclick="{{ $app_is_demo ? 'return toastr.info(\'This feature is disabled in Demo version.\')' : '' }}"
                                >
                                    <div
                                        class="spinner hidden"
                                        id="spinner"
                                    ></div>
                                    @if ($plan->trial_days != 0 && $plan->frequency != 'lifetime_monthly' && $plan->frequency != 'lifetime_yearly' && $plan->price > 0)
                                        {{ __('Start free trial') }}
                                        {{ __('with') }}
                                        <svg
                                            class="h-auto w-14"
                                            width="360"
                                            height="151"
                                            viewBox="0 0 360 151"
                                            fill="currentColor"
                                            xmlns="http://www.w3.org/2000/svg"
                                            fill-rule="evenodd"
                                            clip-rule="evenodd"
                                        >
                                            <path
                                                d="M360 77.6787C360 52.0787 347.6 31.8787 323.9 31.8787C300.1 31.8787 285.7 52.0787 285.7 77.4787C285.7 107.579 302.7 122.779 327.1 122.779C339 122.779 348 120.079 354.8 116.279V96.2787C348 99.6787 340.2 101.779 330.3 101.779C320.6 101.779 312 98.3787 310.9 86.5787H359.8C359.8 85.2787 360 80.0787 360 77.6787ZM310.6 68.1787C310.6 56.8787 317.5 52.1787 323.8 52.1787C329.9 52.1787 336.4 56.8787 336.4 68.1787H310.6Z"
                                            />
                                            <path
                                                d="M247.1 31.8787C237.3 31.8787 231 36.4787 227.5 39.6787L226.2 33.4787H204.2V150.079L229.2 144.779L229.3 116.479C232.9 119.079 238.2 122.779 247 122.779C264.9 122.779 281.2 108.379 281.2 76.6787C281.1 47.6787 264.6 31.8787 247.1 31.8787ZM241.1 100.779C235.2 100.779 231.7 98.6787 229.3 96.0787L229.2 58.9787C231.8 56.0787 235.4 54.0787 241.1 54.0787C250.2 54.0787 256.5 64.2787 256.5 77.3787C256.5 90.7787 250.3 100.779 241.1 100.779Z"
                                            />
                                            <path d="M169.8 25.9787L194.9 20.5787V0.278687L169.8 5.57869V25.9787Z" />
                                            <path d="M194.9 33.5787H169.8V121.079H194.9V33.5787Z" />
                                            <path
                                                d="M142.9 40.9787L141.3 33.5787H119.7V121.079H144.7V61.7787C150.6 54.0787 160.6 55.4787 163.7 56.5787V33.5787C160.5 32.3787 148.8 30.1787 142.9 40.9787Z"
                                            />
                                            <path
                                                d="M92.9 11.8787L68.5 17.0787L68.4 97.1787C68.4 111.979 79.5 122.879 94.3 122.879C102.5 122.879 108.5 121.379 111.8 119.579V99.2787C108.6 100.579 92.8 105.179 92.8 90.3787V54.8787H111.8V33.5787H92.8L92.9 11.8787Z"
                                            />
                                            <path
                                                d="M25.3 58.9787C25.3 55.0787 28.5 53.5787 33.8 53.5787C41.4 53.5787 51 55.8787 58.6 59.9787V36.4787C50.3 33.1787 42.1 31.8787 33.8 31.8787C13.5 31.8787 0 42.4787 0 60.1787C0 87.7787 38 83.3787 38 95.2787C38 99.8787 34 101.379 28.4 101.379C20.1 101.379 9.5 97.9787 1.1 93.3787V117.179C10.4 121.179 19.8 122.879 28.4 122.879C49.2 122.879 63.5 112.579 63.5 94.6787C63.4 64.8787 25.3 70.1787 25.3 58.9787Z"
                                            />
                                        </svg>
                                    @else
                                        {{ __('Pay') }}
                                        {!! displayCurr(currency()->symbol, $plan->price, $taxValue, $newDiscountedPrice, tax_included: $plan->price_tax_included) !!}
                                        {{ __('with') }}
                                        <svg
                                            class="h-auto w-14"
                                            width="360"
                                            height="151"
                                            viewBox="0 0 360 151"
                                            fill="currentColor"
                                            xmlns="http://www.w3.org/2000/svg"
                                            fill-rule="evenodd"
                                            clip-rule="evenodd"
                                        >
                                            <path
                                                d="M360 77.6787C360 52.0787 347.6 31.8787 323.9 31.8787C300.1 31.8787 285.7 52.0787 285.7 77.4787C285.7 107.579 302.7 122.779 327.1 122.779C339 122.779 348 120.079 354.8 116.279V96.2787C348 99.6787 340.2 101.779 330.3 101.779C320.6 101.779 312 98.3787 310.9 86.5787H359.8C359.8 85.2787 360 80.0787 360 77.6787ZM310.6 68.1787C310.6 56.8787 317.5 52.1787 323.8 52.1787C329.9 52.1787 336.4 56.8787 336.4 68.1787H310.6Z"
                                            />
                                            <path
                                                d="M247.1 31.8787C237.3 31.8787 231 36.4787 227.5 39.6787L226.2 33.4787H204.2V150.079L229.2 144.779L229.3 116.479C232.9 119.079 238.2 122.779 247 122.779C264.9 122.779 281.2 108.379 281.2 76.6787C281.1 47.6787 264.6 31.8787 247.1 31.8787ZM241.1 100.779C235.2 100.779 231.7 98.6787 229.3 96.0787L229.2 58.9787C231.8 56.0787 235.4 54.0787 241.1 54.0787C250.2 54.0787 256.5 64.2787 256.5 77.3787C256.5 90.7787 250.3 100.779 241.1 100.779Z"
                                            />
                                            <path d="M169.8 25.9787L194.9 20.5787V0.278687L169.8 5.57869V25.9787Z" />
                                            <path d="M194.9 33.5787H169.8V121.079H194.9V33.5787Z" />
                                            <path
                                                d="M142.9 40.9787L141.3 33.5787H119.7V121.079H144.7V61.7787C150.6 54.0787 160.6 55.4787 163.7 56.5787V33.5787C160.5 32.3787 148.8 30.1787 142.9 40.9787Z"
                                            />
                                            <path
                                                d="M92.9 11.8787L68.5 17.0787L68.4 97.1787C68.4 111.979 79.5 122.879 94.3 122.879C102.5 122.879 108.5 121.379 111.8 119.579V99.2787C108.6 100.579 92.8 105.179 92.8 90.3787V54.8787H111.8V33.5787H92.8L92.9 11.8787Z"
                                            />
                                            <path
                                                d="M25.3 58.9787C25.3 55.0787 28.5 53.5787 33.8 53.5787C41.4 53.5787 51 55.8787 58.6 59.9787V36.4787C50.3 33.1787 42.1 31.8787 33.8 31.8787C13.5 31.8787 0 42.4787 0 60.1787C0 87.7787 38 83.3787 38 95.2787C38 99.8787 34 101.379 28.4 101.379C20.1 101.379 9.5 97.9787 1.1 93.3787V117.179C10.4 121.179 19.8 122.879 28.4 122.879C49.2 122.879 63.5 112.579 63.5 94.6787C63.4 64.8787 25.3 70.1787 25.3 58.9787Z"
                                            />
                                        </svg>
                                    @endif
                                </x-button>
                                <div
                                    class="hidden"
                                    id="payment-message"
                                ></div>
                            </div>
                        </div>
                    </form>
                    <br>
                    <p>{{ __('By purchasing you confirm our') }} <a href="{{ url('/') . '/terms' }}">{{ __('Terms and Conditions') }}</a> </p>
                </div>
                <div class="col-sm-4 col-lg-4">
                    @include('panel.user.finance.partials.plan_card')
                </div>
            </div>
        </div>
    </div>
    {{-- addressModal --}}
    <div
        class="modal fade"
        id="addressModal"
        tabindex="-1"
        role="dialog"
        aria-labelledby="addressModalLabel"
        aria-hidden="true"
    >
        <div
            class="modal-dialog modal-dialog-centered"
            role="document"
        >
            <div class="modal-content">
                <form
                    action="{{ route('dashboard.user.payment.updateAddressDetails', ['gateway' => 'stripe']) }}"
                    method="post"
                >
                    @csrf
                    <div class="modal-header">
                        <h5
                            class="modal-title"
                            id="addressModalLabel"
                        >{{ __('Please fill in your address') }}</h5>
                        <button
                            class="btn-close"
                            data-bs-dismiss="modal"
                            type="button"
                            aria-label="Close"
                        ></button>
                    </div>
                    <div class="modal-body">
                        <div
                            class="alert alert-warning"
                            role="alert"
                        >
                            {{ __('As per Indian regulations, export transactions require a customer full address.') }}
                        </div>
                        <div class="mb-[20px]">
                            <label class="form-label">{{ __('Phone') }}</label>
                            <x-forms.input
                                class="form-control"
                                id="phone"
                                data-mask="+0000000000000"
                                data-mask-visible="true"
                                type="text"
                                name="phone"
                                placeholder="+000000000000"
                                autocomplete="off"
                                value="{{ auth()->user()->phone }}"
                            />
                        </div>
                        <div class="mb-[20px]">
                            <label class="form-label">{{ __('Address Line 1') }}</label>
                            <x-forms.input
                                id="address"
                                type="text"
                                name="address"
                                value="{{ auth()->user()->address }}"
                            />
                        </div>
                        <div class="mb-[20px]">
                            <label class="form-label">{{ __('Postal Code') }}</label>
                            <x-forms.input
                                id="postal"
                                type="text"
                                name="postal"
                                value="{{ auth()->user()->postal }}"
                            />
                        </div>
                        <div class="mb-[20px]">
                            <label class="form-label">{{ __('City') }}</label>
                            <x-forms.input
                                id="city"
                                type="text"
                                name="city"
                                value="{{ auth()->user()->city }}"
                            />
                        </div>
                        <div class="mb-[20px]">
                            <label class="form-label">{{ __('State') }}</label>
                            <x-forms.input
                                id="state"
                                type="text"
                                name="state"
                                value="{{ auth()->user()->state }}"
                            />
                        </div>
                        <div class="mb-[20px]">
                            <label class="form-label">{{ __('Country') }}</label>
                            <select
                                class="form-select"
                                id="country"
                                type="text"
                                name="country"
                            >
                                @include('panel.admin.users.countries')
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button
                            class="btn btn-secondary"
                            data-bs-dismiss="modal"
                            type="button"
                        >{{ __('Close') }}</button>
                        <button
                            class="btn btn-primary"
                            type="submit"
                        >{{ __('Submit') }}</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection

@push('script')
    <script src="{{ custom_theme_url('https://js.stripe.com/v3/') }}"></script>
    <script>
        (() => {
            "use strict";

            const stripe = Stripe(
                "{{ $gateway->mode == 'live' ? $gateway->live_client_id : $gateway->sandbox_client_id }}");
            let elements;
            initialize();
            if (!"{{ $paymentIntent['client_secret'] }}".startsWith("set")) {
                checkStatus();
            }
            document.querySelector("#payment-form").addEventListener("submit", handleSubmit);
            async function initialize() {
                const clientSecret = "{{ $paymentIntent['client_secret'] }}";
                elements = stripe.elements({
                    clientSecret
                });
                const paymentElementOptions = {
                    layout: "tabs",
                    business: {
                        name: "{{ config('app.name') }}"
                    },
                };
                const paymentElement = elements.create("payment", paymentElementOptions);
                paymentElement.mount("#payment-element");
            }
            async function handleSubmit(e) {
                e.preventDefault();
                setLoading(true);
                const secret = "{{ $paymentIntent['client_secret'] }}";
                let url = `{{ route('dashboard.user.payment.subscription.checkout', ['gateway' => ':gateway']) }}`;
                url = url.replace(':gateway', 'stripe');
                if (typeof rewardful !== 'undefined') {
                    rewardful('ready', function() {
                        if (Rewardful.referral) {
                            url =
                                `{{ route('dashboard.user.payment.subscription.checkout', ['gateway' => ':gateway'], ['referral' => ':referral']) }}`;
                            url = url.replace(':referral', Rewardful.referral);
                            url = url.replace(':gateway', 'stripe');
                        }
                    });
                }
                const confirmParams = {
                    elements,
                    confirmParams: {
                        return_url: url,
                        payment_method_data: {
                            billing_details: {
                                name: '{{ auth()->user()?->fullName() }}',
                                email: '{{ auth()->user()->email }}',
                                phone: '{{ auth()->user()->phone }}',
                                address: {
                                    country: '{{ \App\Services\CountryCodeService::getCountryCode(auth()->user()->country) }}',
                                    city: '{{ auth()->user()->city }}',
                                    line1: '{{ auth()->user()->address }}',
                                    postal_code: '{{ auth()->user()->postal }}',
                                    state: '{{ auth()->user()->state }}',
                                }
                            }
                        },
                    },
                };
                if (!secret.startsWith("set")) {
                    const error = await stripe.confirmPayment(confirmParams);
                } else {
                    const error = await stripe.confirmSetup(confirmParams);
                }
                const confirmFunction = secret.startsWith("set") ? stripe.confirmSetup : stripe.confirmPayment;
                const error = await confirmFunction(confirmParams);
                if (error.error.type === "invalid_request_error" && error.error.message.startsWith("As per Indian regulations,")) {
                    $('#addressModal').modal('show');
                } else {
                    showMessage(error.error.message);
                }
                setLoading(false);
            }
            async function checkStatus() {
                const clientSecret = "{{ $paymentIntent['client_secret'] }}";
                if (!clientSecret) {
                    return;
                }
                const {
                    paymentIntent
                } = await stripe.retrievePaymentIntent(clientSecret);

                switch (paymentIntent.status) {
                    case "succeeded":
                        showMessage("Payment succeeded!");
                        break;
                    case "processing":
                        showMessage("Your payment is processing.");
                        break;
                    case "requires_payment_method":
                        showMessage("Select a valid payment method to proceed.");
                        break;
                    default:
                        break;
                }
            }

            function showMessage(messageText) {
                const messageContainer = document.querySelector("#payment-message");
                messageContainer.classList.remove("hidden");
                messageContainer.textContent = messageText;
                setTimeout(() => {
                    messageContainer.classList.add("hidden");
                    messageContainer.textContent = "";
                }, 7000);
            }

            function setLoading(isLoading) {
                const submitButton = document.querySelector("#submit");
                const spinner = document.querySelector("#spinner");
                const buttonText = document.querySelector("#button-text");

                submitButton.disabled = isLoading;
                spinner?.classList?.toggle("hidden", !isLoading);
                buttonText?.classList?.toggle("hidden", isLoading);
            }

        })();
    </script>
@endpush
