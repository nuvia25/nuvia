<x-card
    class="flex flex-col"
    class:body="flex flex-col justify-center grow gap-10"
    id="{{ 'admin-card-' . ($widget?->name?->value ?? 'recent-activity') }}"
>
    <x-slot:head
        class="flex items-center justify-between px-5 py-3.5"
    >
        <div class="flex items-center gap-4">
            <x-lqd-icon class="bg-background text-heading-foreground dark:bg-foreground/5">
                <x-tabler-notification
                    class="size-6"
                    stroke-width="1.5"
                />
            </x-lqd-icon>
            <h4 class="m-0 flex items-center gap-1 text-base font-medium">
                {{ __('Recent Activity') }}
                <x-info-tooltip text="{{ __('Latest actions performed by users on your platform.') }}" />
            </h4>
        </div>
    </x-slot:head>
    @foreach (cache('recent_activity') as $activity)
        <div class="flex justify-between gap-10">
            <div class="grid w-full grid-cols-12 items-center">
                <div class="col-span-4 mr-3 flex items-center justify-between sm:col-span-3">
                    <span>{{ $activity->created_at->format('g:i A') }}</span>
                    <span
                        class="{{ $loop->last ? '' : 'after:w-px after:bg-foreground/10 after:absolute after:start-1/2 after:-bottom-20 after:h-20' }} relative size-2 rounded-full bg-foreground/80"
                    ></span>
                </div>
                <div class="col-span-7 flex gap-1">
                    <img
                        class="size-10 rounded-full"
                        src="{{ asset($activity->user?->avatar ?? 'testimonialAvatar/202305300751avatar-1.jpg') }}"
                        alt=""
                    >
                    <div class="flex w-full flex-col">
                        <span class="w-full truncate text-foreground/80"><strong
                                class="text-foreground">{{ $activity->user?->name }}</strong> purchased
                            <strong class="text-foreground">"{{ $activity->plan?->name }}"</strong></span>
                        <span class="text-foreground/80">{{ $activity->created_at->diffForHumans() }}</span>
                    </div>
                </div>
            </div>
            <span class="size-2 shrink-0 self-center rounded-full bg-[#55B587]"></span>
        </div>
    @endforeach
</x-card>
